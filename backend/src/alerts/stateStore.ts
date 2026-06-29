import { getFirestore } from 'firebase-admin/firestore';

import { getFirebaseApp } from '../push/firebase';

/**
 * 관서(stnId)별로 "마지막으로 푸시한 특보 발표시각(tmFc)"을 Firestore에 저장한다.
 * Render 무료 티어는 파일시스템이 배포·재시작마다 초기화되므로(영구 디스크 없음),
 * 이미 쓰고 있는 Firebase 프로젝트의 Firestore에 상태를 둔다 — 추가 인프라 0.
 * (서버는 admin SDK라 보안 규칙을 우회하므로 별도 규칙 설정 불필요.)
 */
const COLLECTION = 'alertPushState';

export async function getLastPushedTmFc(stnId: string): Promise<number | null> {
  const snap = await getFirestore(getFirebaseApp()).collection(COLLECTION).doc(stnId).get();
  const tmFc = snap.data()?.tmFc;
  return typeof tmFc === 'number' ? tmFc : null;
}

export async function setLastPushedTmFc(stnId: string, tmFc: number): Promise<void> {
  await getFirestore(getFirebaseApp())
    .collection(COLLECTION)
    .doc(stnId)
    .set({ tmFc, updatedAt: Date.now() });
}
