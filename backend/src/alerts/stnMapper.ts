/**
 * 기상청 특보 API는 시군구 단위가 아니라 관서(stnId) 단위로만 특보를 제공한다.
 * 하지만 통보문 본문(t6)에는 실제 영향 시/도가 이름으로 적혀 있어, 발송 대상은
 * 관서가 아니라 "본문에 실제 언급된 시/도" 단위로 좁힐 수 있다(푸시 과다 방지).
 *
 * lib/data/alert/kma_stn_mapper.dart와 매핑을 공유한다 — 한쪽을 고치면 반드시
 * 다른 쪽도 맞춰야 한다.
 */

/** 관서 권역 표시명(로그용). 전국(108)은 푸시 대상 아님. */
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

/**
 * 시/도(regions.json의 province 표기) → FCM 토픽용 ASCII 코드.
 * FCM 토픽명은 [a-zA-Z0-9-_.~%]만 허용해 한글 시/도명을 그대로 못 쓴다 → 코드로 매핑.
 * lib/data/alert/kma_stn_mapper.dart의 _provinceCode와 반드시 동일하게 유지.
 */
const PROVINCE_CODES: Record<string, string> = {
  서울특별시: 'seoul',
  인천광역시: 'incheon',
  경기도: 'gyeonggi',
  강원특별자치도: 'gangwon',
  충청북도: 'chungbuk',
  대전광역시: 'daejeon',
  세종특별자치시: 'sejong',
  충청남도: 'chungnam',
  전북특별자치도: 'jeonbuk',
  광주광역시: 'gwangju',
  전라남도: 'jeonnam',
  대구광역시: 'daegu',
  경상북도: 'gyeongbuk',
  부산광역시: 'busan',
  울산광역시: 'ulsan',
  경상남도: 'gyeongnam',
  제주특별자치도: 'jeju',
};

/** 각 관서가 담당하는 시/도 목록. 본문에서 이 중 실제 언급된 시/도만 추려 발송한다. */
const PROVINCES_BY_STN: Record<string, string[]> = {
  '109': ['서울특별시', '인천광역시', '경기도'],
  '105': ['강원특별자치도'],
  '131': ['충청북도'],
  '133': ['대전광역시', '세종특별자치시', '충청남도'],
  '146': ['전북특별자치도'],
  '156': ['광주광역시', '전라남도'],
  '143': ['대구광역시', '경상북도'],
  '159': ['부산광역시', '울산광역시', '경상남도'],
  '184': ['제주특별자치도'],
};

/**
 * 특보 본문에서 시/도를 식별하기 위한 별칭. 통보문은 "대전"·"충남" 같은 축약형을 주로
 * 쓰지만 "충청남도"처럼 전체 표기가 나올 때도 있어 둘 다 등록한다.
 * (놓침 = 내 지역 실특보 미수신이 최악이므로 넉넉하게 매칭한다.)
 */
const PROVINCE_ALIASES: Record<string, string[]> = {
  서울특별시: ['서울'],
  인천광역시: ['인천'],
  경기도: ['경기'],
  강원특별자치도: ['강원'],
  충청북도: ['충북', '충청북도'],
  대전광역시: ['대전'],
  세종특별자치시: ['세종'],
  충청남도: ['충남', '충청남도'],
  전북특별자치도: ['전북', '전라북도'],
  광주광역시: ['광주'],
  전라남도: ['전남', '전라남도'],
  대구광역시: ['대구'],
  경상북도: ['경북', '경상북도'],
  부산광역시: ['부산'],
  울산광역시: ['울산'],
  경상남도: ['경남', '경상남도'],
  제주특별자치도: ['제주'],
};

export const PUSH_STN_IDS = Object.keys(PROVINCES_BY_STN);

export function labelForStnId(stnId: string): string {
  return STN_LABELS[stnId] ?? stnId;
}

/** 관서가 담당하는 시/도 목록(미등록이면 빈 배열). */
export function provincesForStn(stnId: string): string[] {
  return PROVINCES_BY_STN[stnId] ?? [];
}

/** 시/도 → 토픽 코드(미등록이면 null). */
export function provinceCode(province: string): string | null {
  return PROVINCE_CODES[province] ?? null;
}

/** 앱이 구독할 FCM 토픽 이름. lib에서도 이 규칙을 그대로 따른다. */
export function topicForProvinceCode(code: string): string {
  return `prov_${code}`;
}

/**
 * 특보 본문(t6)에서 candidateProvinces 중 실제로 이름이 언급된 시/도만 골라 반환한다.
 * candidateProvinces는 해당 관서가 담당하는 시/도 목록을 넘기는 걸 전제로 한다 —
 * 다른 관서 소속 지역명이 우연히 섞여도 오탐되지 않게 후보를 관서 범위로 제한한다.
 */
export function provincesInAlertBody(body: string, candidateProvinces: string[]): string[] {
  return candidateProvinces.filter((province) =>
    (PROVINCE_ALIASES[province] ?? []).some((alias) => body.includes(alias)),
  );
}
