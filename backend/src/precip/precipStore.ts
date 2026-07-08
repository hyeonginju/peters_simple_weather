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
 * slot(예: "202607091400")이 마지막 반영分과 같으면 건너뛴다 — 5분마다 도는 폴링이
 * 같은 시간대를 여러 번 봐도 중복 합산되지 않게 막는 가드.
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
