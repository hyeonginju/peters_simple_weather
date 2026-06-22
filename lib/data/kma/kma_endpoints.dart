class KmaEndpoints {
  KmaEndpoints._();

  static const _villageFcstBase = 'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0';
  static const _midFcstBase = 'https://apis.data.go.kr/1360000/MidFcstInfoService';
  static const _wthrWrnBase = 'https://apis.data.go.kr/1360000/WthrWrnInfoService';

  static const vilageFcst = '$_villageFcstBase/getVilageFcst';
  static const ultraSrtNcst = '$_villageFcstBase/getUltraSrtNcst';
  static const midLandFcst = '$_midFcstBase/getMidLandFcst';
  static const midTa = '$_midFcstBase/getMidTa';
  static const wthrWrnMsg = '$_wthrWrnBase/getWthrWrnMsg';
}
