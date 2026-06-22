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

  /// province(시/도)에 해당하는 stnId. 미등록이면 전국(108)으로 폴백.
  static String stnIdForProvince(String province) => _byProvince[province] ?? nationwide;

  static String labelForStnId(String stnId) => _regionLabel[stnId] ?? '전국';
}
