/**
 * 기상청 특보 API는 시군구 단위가 아니라 관서(stnId) 단위로만 특보를 제공한다.
 * lib/data/alert/kma_stn_mapper.dart의 _byProvince와 동일한 매핑에서 고유 stnId만 추출.
 * 전국(108)은 푸시 대상에서 제외 — 푸시는 "대표 지역" 기준이라 항상 9개 중 하나로 매핑됨.
 */
const STN_LABELS: Record<string, string> = {
  '109': '서울·인천·경기',
  '105': '강원도',
  '131': '충청북도',
  '133': '대전·세종·충남',
  '146': '전북',
  '156': '광주·전남',
  '143': '대구·경북',
  '159': '부산·울산·경남',
  '184': '제주도',
};

export const PUSH_STN_IDS = Object.keys(STN_LABELS);

export function labelForStnId(stnId: string): string {
  return STN_LABELS[stnId] ?? stnId;
}

/** 앱이 구독할 FCM 토픽 이름. lib에서도 이 규칙을 그대로 따른다. */
export function topicForStnId(stnId: string): string {
  return `stn_${stnId}`;
}
