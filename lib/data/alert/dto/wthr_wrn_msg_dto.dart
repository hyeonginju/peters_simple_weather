import 'package:json_annotation/json_annotation.dart';

part 'wthr_wrn_msg_dto.g.dart';

/// getWthrWrnMsg(기상특보 통보문) 응답 1건. 발표 시점의 특보 통보문 전문.
/// 필드 의미:
/// - t1: 통보 제목(최근 발표/해제 내용, 예 "호우주의보 해제")
/// - t2/t3: 발표·해제 구역 및 시각 상세
/// - t6: 현재 발효 중인 특보 ("o 없음"이면 발효 없음)
/// - t7: 예비특보
/// - tmFc: 발표 시각(yyyyMMddHHmm)
@JsonSerializable()
class WthrWrnMsgDto {
  final String stnId;
  final String? t1;
  final String? t6;
  final String? t7;
  final int? tmFc;

  const WthrWrnMsgDto({
    required this.stnId,
    this.t1,
    this.t6,
    this.t7,
    this.tmFc,
  });

  factory WthrWrnMsgDto.fromJson(Map<String, dynamic> json) => _$WthrWrnMsgDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WthrWrnMsgDtoToJson(this);
}
