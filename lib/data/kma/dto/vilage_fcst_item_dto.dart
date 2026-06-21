import 'package:json_annotation/json_annotation.dart';

part 'vilage_fcst_item_dto.g.dart';

/// One row of getVilageFcst's flat, category-per-row response.
@JsonSerializable()
class VilageFcstItemDto {
  final String category;
  final String fcstDate;
  final String fcstTime;
  final String fcstValue;

  const VilageFcstItemDto({
    required this.category,
    required this.fcstDate,
    required this.fcstTime,
    required this.fcstValue,
  });

  factory VilageFcstItemDto.fromJson(Map<String, dynamic> json) => _$VilageFcstItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VilageFcstItemDtoToJson(this);
}
