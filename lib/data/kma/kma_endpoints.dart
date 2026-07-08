/// KMA를 직접 호출하지 않고 백엔드 프록시(backend/src/routes/weather.ts)를 거친다 —
/// serviceKey가 앱 번들에 들어가지 않도록 서버에서만 보관한다.
class KmaEndpoints {
  KmaEndpoints._();

  static const _base = 'https://peters-weather-backend.onrender.com/api/weather';

  static const vilageFcst = '$_base/vilage-fcst';
  static const ultraSrtNcst = '$_base/ultra-srt-ncst';
  static const midLandFcst = '$_base/mid-land-fcst';
  static const midTa = '$_base/mid-ta';
  static const wthrWrnMsg = '$_base/wthr-wrn-msg';
  static const precipToday = '$_base/precip-today';
}
