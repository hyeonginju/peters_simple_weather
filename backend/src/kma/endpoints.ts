const villageFcstBase = 'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0';
const midFcstBase = 'https://apis.data.go.kr/1360000/MidFcstInfoService';
const wthrWrnBase = 'https://apis.data.go.kr/1360000/WthrWrnInfoService';

/** 앱이 호출하던 5개 KMA 엔드포인트. (lib/data/kma/kma_endpoints.dart와 1:1) */
export const KMA_ENDPOINTS = {
  vilageFcst: `${villageFcstBase}/getVilageFcst`,
  ultraSrtNcst: `${villageFcstBase}/getUltraSrtNcst`,
  midLandFcst: `${midFcstBase}/getMidLandFcst`,
  midTa: `${midFcstBase}/getMidTa`,
  wthrWrnMsg: `${wthrWrnBase}/getWthrWrnMsg`,
} as const;

// 에어코리아(한국환경공단, data.go.kr B552584). serviceKey는 KMA와 동일한
// data.go.kr 계정 키를 그대로 쓴다(별도 활용신청만 추가). 앱은 이 URL을 모르고
// /api/weather/air-quality 프록시만 호출한다 — 그래서 KMA_ENDPOINTS와 달리
// 앱 쪽 미러가 없다.
const airKoreaBase = 'https://apis.data.go.kr/B552584';

export const AIR_ENDPOINTS = {
  /** 측정소정보 조회 — addr(시도명)로 측정소 목록(측정소명+주소)을 받는다. */
  msrstnList: `${airKoreaBase}/MsrstnInfoInqireSvc/getMsrstnList`,
  /** 대기오염정보 조회 — stationName으로 실시간 PM10/PM2.5/통합지수를 받는다. */
  realtime: `${airKoreaBase}/ArpltnInforInqireSvc/getMsrstnAcctoRltmMesureDnsty`,
} as const;
