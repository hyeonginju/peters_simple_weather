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

  String get displayName => '$province $name';

  @override
  bool operator ==(Object other) => other is Region && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
