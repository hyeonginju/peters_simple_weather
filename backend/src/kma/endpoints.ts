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
