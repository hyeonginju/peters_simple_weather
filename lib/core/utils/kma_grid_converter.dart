import 'dart:math' as math;

/// Converts WGS84 latitude/longitude to the KMA short-term-forecast grid
/// (NX, NY) using the気象庁 Lambert Conformal Conic parameters. This is the
/// exact algorithm KMA itself uses to build its official 격자 좌표 table, so
/// given an accurate representative lat/lon for a district the result matches
/// the published NX/NY.
({int nx, int ny}) latLonToGrid(double lat, double lon) {
  const re = 6371.00877; // Earth radius (km)
  const grid = 5.0; // grid spacing (km)
  const slat1 = 30.0; // projection latitude 1 (deg)
  const slat2 = 60.0; // projection latitude 2 (deg)
  const olon = 126.0; // reference longitude (deg)
  const olat = 38.0; // reference latitude (deg)
  const xo = 43; // reference X (grid)
  const yo = 136; // reference Y (grid)

  const degrad = math.pi / 180.0;
  final reGrid = re / grid;
  final slat1Rad = slat1 * degrad;
  final slat2Rad = slat2 * degrad;
  final olonRad = olon * degrad;
  final olatRad = olat * degrad;

  var sn = math.tan(math.pi * 0.25 + slat2Rad * 0.5) / math.tan(math.pi * 0.25 + slat1Rad * 0.5);
  sn = math.log(math.cos(slat1Rad) / math.cos(slat2Rad)) / math.log(sn);
  var sf = math.tan(math.pi * 0.25 + slat1Rad * 0.5);
  sf = math.pow(sf, sn) * math.cos(slat1Rad) / sn;
  var ro = math.tan(math.pi * 0.25 + olatRad * 0.5);
  ro = reGrid * sf / math.pow(ro, sn);

  var ra = math.tan(math.pi * 0.25 + lat * degrad * 0.5);
  ra = reGrid * sf / math.pow(ra, sn);
  var theta = lon * degrad - olonRad;
  if (theta > math.pi) theta -= 2.0 * math.pi;
  if (theta < -math.pi) theta += 2.0 * math.pi;
  theta *= sn;

  final nx = (ra * math.sin(theta) + xo + 0.5).floor();
  final ny = (ro - ra * math.cos(theta) + yo + 0.5).floor();
  return (nx: nx, ny: ny);
}
