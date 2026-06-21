import 'package:json_annotation/json_annotation.dart';

part 'ultra_srt_ncst_item_dto.g.dart';

/// One row of getUltraSrtNcst — a "right now" observation snapshot, so
/// (unlike getVilageFcst) there's no fcstDate/fcstTime per row; every item
/// shares the requested baseDate/baseTime.
@JsonSerializable()
class UltraSrtNcstItemDto {
  final String category;
  final String obsrValue;

  const UltraSrtNcstItemDto({
    required this.category,
    required this.obsrValue,
  });

  factory UltraSrtNcstItemDto.fromJson(Map<String, dynamic> json) => _$UltraSrtNcstItemDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UltraSrtNcstItemDtoToJson(this);
}
