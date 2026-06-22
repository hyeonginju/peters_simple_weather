// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wthr_wrn_msg_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WthrWrnMsgDto _$WthrWrnMsgDtoFromJson(Map<String, dynamic> json) =>
    WthrWrnMsgDto(
      stnId: json['stnId'] as String,
      t1: json['t1'] as String?,
      t6: json['t6'] as String?,
      t7: json['t7'] as String?,
      tmFc: (json['tmFc'] as num?)?.toInt(),
    );

Map<String, dynamic> _$WthrWrnMsgDtoToJson(WthrWrnMsgDto instance) =>
    <String, dynamic>{
      'stnId': instance.stnId,
      't1': instance.t1,
      't6': instance.t6,
      't7': instance.t7,
      'tmFc': instance.tmFc,
    };
