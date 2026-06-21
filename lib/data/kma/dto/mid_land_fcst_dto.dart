import 'package:json_annotation/json_annotation.dart';

part 'mid_land_fcst_dto.g.dart';

/// getMidLandFcst's response: one flat object per region with day-indexed
/// fields (오늘+3 ~ 오늘+10). Days 3-7 split AM/PM 강수확률(rnSt)/날씨(wf);
/// days 8-10 only have a single daily value.
@JsonSerializable()
class MidLandFcstDto {
  final String regId;

  final int? rnSt3Am;
  final int? rnSt3Pm;
  final int? rnSt4Am;
  final int? rnSt4Pm;
  final int? rnSt5Am;
  final int? rnSt5Pm;
  final int? rnSt6Am;
  final int? rnSt6Pm;
  final int? rnSt7Am;
  final int? rnSt7Pm;
  final int? rnSt8;
  final int? rnSt9;
  final int? rnSt10;

  final String? wf3Am;
  final String? wf3Pm;
  final String? wf4Am;
  final String? wf4Pm;
  final String? wf5Am;
  final String? wf5Pm;
  final String? wf6Am;
  final String? wf6Pm;
  final String? wf7Am;
  final String? wf7Pm;
  final String? wf8;
  final String? wf9;
  final String? wf10;

  const MidLandFcstDto({
    required this.regId,
    this.rnSt3Am,
    this.rnSt3Pm,
    this.rnSt4Am,
    this.rnSt4Pm,
    this.rnSt5Am,
    this.rnSt5Pm,
    this.rnSt6Am,
    this.rnSt6Pm,
    this.rnSt7Am,
    this.rnSt7Pm,
    this.rnSt8,
    this.rnSt9,
    this.rnSt10,
    this.wf3Am,
    this.wf3Pm,
    this.wf4Am,
    this.wf4Pm,
    this.wf5Am,
    this.wf5Pm,
    this.wf6Am,
    this.wf6Pm,
    this.wf7Am,
    this.wf7Pm,
    this.wf8,
    this.wf9,
    this.wf10,
  });

  factory MidLandFcstDto.fromJson(Map<String, dynamic> json) => _$MidLandFcstDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MidLandFcstDtoToJson(this);
}
