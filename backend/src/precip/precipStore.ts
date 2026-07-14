import { getFirestore } from 'firebase-admin/firestore';

import { getFirebaseApp } from '../push/firebase';

/**
 * 격자 셀(nx,ny)별 "오늘(KST) 00시~마지막으로 관측된 시간대까지" 누적 RN1(mm)을
 * Firestore에 저장한다. alerts/stateStore.ts와 같은 이유로 Firestore를 쓴다 —
 * Render 무료 티어는 파일시스템이 재시작마다 초기화되므로 영구 저장소가 필요.
 */
const COLLECTION = 'precipToday';

function docId(nx: number, ny: number, dateKey: string): string {
  return `${nx}_${ny}_${dateKey}`;
}

export type PrecipState = { accumulatedRn: number; lastSlot: string | null };

export async function getPrecipState(nx: number, ny: number, dateKey: string): Promise<PrecipState> {
  const snap = await getFirestore(getFirebaseApp()).collection(COLLECTION).doc(docId(nx, ny, dateKey)).get();
  const data = snap.data();
  return {
    accumulatedRn: typeof data?.accumulatedRn === 'number' ? data.accumulatedRn : 0,
    lastSlot: typeof data?.lastSlot === 'string' ? data.lastSlot : null,
  };
}

/**
 * slot(예: "202607091400")이 마지막 반영分과 같으면 건너뛴다 — poller.ts의
 * lastPolledSlot 가드를 통과한 뒤에도 남는 이중 안전장치.
 */
export async function addObservedRn(
  nx: number,
  ny: number,
  dateKey: string,
  slot: string,
  rn: number,
): Promise<void> {
  const db = getFirestore(getFirebaseApp());
  const ref = db.collection(COLLECTION).doc(docId(nx, ny, dateKey));

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    const prevSlot = typeof data?.lastSlot === 'string' ? data.lastSlot : null;
    if (prevSlot === slot) return;

    const prevSum = typeof data?.accumulatedRn === 'number' ? data.accumulatedRn : 0;
    tx.set(ref, { accumulatedRn: prevSum + rn, lastSlot: slot, updatedAt: Date.now() });
  });
}

/**
 * 격자 셀 단위로 "실제로 조회되고 있는지"를 추적한다. 강수 폴러(poller.ts)가 전국
 * 셀을 무조건 도는 대신 이 컬렉션에 최근 등록된 셀만 도는 데 쓰인다.
 * firstActiveDate는 최초 조회일 이후 불변 — "이 셀이 처음 쓰이기 시작한 날"을
 * 나타내며, 그날은 아직 실측 데이터가 없으므로 예보값만 보여주는 기준이 된다.
 */
const ACTIVE_CELLS_COLLECTION = 'activeCells';

function activeCellDocId(nx: number, ny: number): string {
  return `${nx}_${ny}`;
}

/** 셀을 활성으로 표시(없으면 생성, 있으면 lastRequestedAt만 갱신)하고 firstActiveDate를 반환한다. */
export async function touchActiveCell(nx: number, ny: number, todayDateKey: string): Promise<string> {
  const db = getFirestore(getFirebaseApp());
  const ref = db.collection(ACTIVE_CELLS_COLLECTION).doc(activeCellDocId(nx, ny));

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    const firstActiveDate = typeof data?.firstActiveDate === 'string' ? data.firstActiveDate : todayDateKey;
    tx.set(ref, { firstActiveDate, lastRequestedAt: Date.now() });
    return firstActiveDate;
  });
}

export type ActiveCell = { nx: number; ny: number };

/** maxAgeMs 이내에 조회된 적 있는 셀만 반환한다 — 강수 폴러가 이 목록만 순회한다. */
export async function getActiveCells(maxAgeMs: number): Promise<ActiveCell[]> {
  const db = getFirestore(getFirebaseApp());
  const cutoff = Date.now() - maxAgeMs;
  const snap = await db.collection(ACTIVE_CELLS_COLLECTION).where('lastRequestedAt', '>=', cutoff).get();

  return snap.docs.map((doc) => {
    const [nx, ny] = doc.id.split('_').map(Number);
    return { nx, ny };
  });
}
