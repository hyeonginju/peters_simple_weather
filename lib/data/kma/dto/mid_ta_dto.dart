import 'package:json_annotation/json_annotation.dart';

part 'mid_ta_dto.g.dart';

/// getMidTa's response: one flat object per region with day-indexed
/// 최저/최고 기온 fields (오늘+3 ~ 오늘+10), no AM/PM split.
@JsonSerializable()
class MidTaDto {
  final String regId;

  final double? taMin3;
  final double? taMax3;
  final double? taMin4;
  final double? taMax4;
  final double? taMin5;
  final double? taMax5;
  final double? taMin6;
  final double? taMax6;
  final double? taMin7;
  final double? taMax7;
  final double? taMin8;
  final double? taMax8;
  final double? taMin9;
  final double? taMax9;
  final double? taMin10;
  final double? taMax10;

  const MidTaDto({
    required this.regId,
    this.taMin3,
    this.taMax3,
    this.taMin4,
    this.taMax4,
    this.taMin5,
    this.taMax5,
    this.taMin6,
    this.taMax6,
    this.taMin7,
    this.taMax7,
    this.taMin8,
    this.taMax8,
    this.taMin9,
    this.taMax9,
    this.taMin10,
    this.taMax10,
  });

  factory MidTaDto.fromJson(Map<String, dynamic> json) => _$MidTaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$MidTaDtoToJson(this);
}
