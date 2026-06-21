// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vilage_fcst_item_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VilageFcstItemDto _$VilageFcstItemDtoFromJson(Map<String, dynamic> json) =>
    VilageFcstItemDto(
      category: json['category'] as String,
      fcstDate: json['fcstDate'] as String,
      fcstTime: json['fcstTime'] as String,
      fcstValue: json['fcstValue'] as String,
    );

Map<String, dynamic> _$VilageFcstItemDtoToJson(VilageFcstItemDto instance) =>
    <String, dynamic>{
      'category': instance.category,
      'fcstDate': instance.fcstDate,
      'fcstTime': instance.fcstTime,
      'fcstValue': instance.fcstValue,
    };
