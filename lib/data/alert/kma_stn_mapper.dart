/// 기상청 특보 API는 nx/ny가 아니라 기상관서(stnId) 단위로 특보를 제공한다.
/// 시군구 단위는 없고, 광역권(관서) 단위가 최소 단위다. 아래는 행정 시/도
/// (regions.json의 province 표기) → 담당 기상관서 stnId 매핑.
class KmaStnMapper {
  KmaStnMapper._();

  /// 전국 종합 통보문 관서 코드.
  static const nationwide = '108';

  static const _byProvince = <String, String>{
    '서울특별시': '109',
    '인천광역시': '109',
    '경기도': '109',
    '강원특별자치도': '105',
    '충청북도': '131',
    '대전광역시': '133',
    '세종특별자치시': '133',
    '충청남도': '133',
    '전북특별자치도': '146',
    '광주광역시': '156',
    '전라남도': '156',
    '대구광역시': '143',
    '경상북도': '143',
    '부산광역시': '159',
    '울산광역시': '159',
    '경상남도': '159',
    '제주특별자치도': '184',
  };

  /// 각 관서가 담당하는 권역 표시명(특보 화면 헤더용).
  static const _regionLabel = <String, String>{
    '108': '전국',
    '109': '서울·인천·경기',
    '105': '강원도',
    '131': '충청북도',
    '133': '대전·세종·충남',
    '146': '전북',
    '156': '광주·전남',
    '143': '대구·경북',
    '159': '부산·울산·경남',
    '184': '제주도',
  };

  /// 시/도 → FCM 토픽용 ASCII 코드. FCM 토픽명은 한글을 못 써서 코드로 매핑한다.
  /// backend/src/alerts/stnMapper.ts의 PROVINCE_CODES와 반드시 동일하게 유지.
  static const _provinceCode = <String, String>{
    '서울특별시': 'seoul',
    '인천광역시': 'incheon',
    '경기도': 'gyeonggi',
    '강원특별자치도': 'gangwon',
    '충청북도': 'chungbuk',
    '대전광역시': 'daejeon',
    '세종특별자치시': 'sejong',
    '충청남도': 'chungnam',
    '전북특별자치도': 'jeonbuk',
    '광주광역시': 'gwangju',
    '전라남도': 'jeonnam',
    '대구광역시': 'daegu',
    '경상북도': 'gyeongbuk',
    '부산광역시': 'busan',
    '울산광역시': 'ulsan',
    '경상남도': 'gyeongnam',
    '제주특별자치도': 'jeju',
  };

  /// province(시/도)에 해당하는 stnId. 미등록이면 전국(108)으로 폴백.
  static String stnIdForProvince(String province) => _byProvince[province] ?? nationwide;

  static String labelForStnId(String stnId) => _regionLabel[stnId] ?? '전국';

  /// 대표 지역 시/도의 특보 FCM 토픽. 미등록 시/도면 null(구독 안 함).
  /// 백엔드가 본문에 이 시/도가 언급된 특보만 이 토픽으로 보내므로, 같은 관서라도
  /// 내 시/도가 아닌 특보(예: 세종 폭염)는 오지 않는다.
  /// backend/src/alerts/stnMapper.ts의 topicForProvinceCode와 동일 규칙 — 한쪽을
  /// 고치면 반드시 다른 쪽도 맞출 것.
  static String? topicForProvince(String province) {
    final code = _provinceCode[province];
    return code == null ? null : 'prov_$code';
  }
}
