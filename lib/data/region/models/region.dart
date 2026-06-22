/// A 시/군/구 entry statically mapped to the KMA grid coordinates and
/// region codes needed to query the various forecast endpoints.
class Region {
  final String id;
  final String province;
  final String name;
  final int nx;
  final int ny;
  final String? midLandCode;
  final String? midTaCode;

  const Region({
    required this.id,
    required this.province,
    required this.name,
    required this.nx,
    required this.ny,
    this.midLandCode,
    this.midTaCode,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as String,
      province: json['province'] as String,
      name: json['name'] as String,
      nx: json['nx'] as int,
      ny: json['ny'] as int,
      midLandCode: json['midLandCode'] as String?,
      midTaCode: json['midTaCode'] as String?,
    );
  }

  String get displayName => province == name ? name : '$province $name';

  /// 세종특별자치시처럼 시/군/구 구분이 없어 province와 name이 같은 경우,
  /// 화면에 둘을 나란히 보여주면 텍스트가 중복된다. 그런 지역에서는 null을
  /// 반환해 상위 위젯이 보조 라벨을 생략하도록 한다.
  String? get provinceLabel => province == name ? null : province;

  @override
  bool operator ==(Object other) => other is Region && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
