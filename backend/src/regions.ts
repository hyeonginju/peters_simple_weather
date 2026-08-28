import regionsJson from './regions.json';

/**
 * 앱이 실제로 조회할 수 있는 지역만 프록시가 KMA로 통과시키게 하는 화이트리스트.
 *
 * 검증이 없으면 임의의 nx/ny로 activeCells 문서를 무제한 만들 수 있고(강수 폴러가
 * 등록된 셀을 매시간 KMA로 조회하므로 요청 한 번이 48시간치 호출로 증폭된다),
 * air-quality의 province/name 캐시도 무한히 커진다. 격자 범위로 열어두는 것보다
 * 실제 지역 목록으로 못박는 편이 확실하다.
 *
 * 이 폴더의 regions.json은 assets/data/regions.json의 사본이다 — 원본은 앱 자산이라
 * 백엔드 빌드(rootDir: src)에 포함되지 않는다. 둘이 어긋나면 regions.test.ts가 실패한다.
 */
type Region = { id: string; province: string; name: string; nx: number; ny: number; midLandCode: string; midTaCode: string };

export const REGIONS: Region[] = regionsJson;

const cells = new Set(REGIONS.map((r) => `${r.nx}_${r.ny}`));
const regionKeys = new Set(REGIONS.map((r) => `${r.province}/${r.name}`));
const midLandCodes = new Set(REGIONS.map((r) => r.midLandCode));
const midTaCodes = new Set(REGIONS.map((r) => r.midTaCode));

/**
 * 격자 좌표가 실제 지역의 것인지. 쿼리스트링에서 온 문자열을 그대로 받는다 —
 * "61.0"이나 "0061"처럼 같은 수를 가리키는 다른 표기는 별개의 Firestore 문서 ID가
 * 되므로 통과시키지 않는다(문서 ID가 곧 `${nx}_${ny}`다).
 */
export function isKnownCell(nx: unknown, ny: unknown): boolean {
  return cells.has(`${String(nx)}_${String(ny)}`);
}

/** province/name 조합이 지역 목록에 있는지(대기질 조회용). */
export function isKnownRegion(province: unknown, name: unknown): boolean {
  return regionKeys.has(`${String(province)}/${String(name)}`);
}

/** 중기육상예보 구역 코드인지. */
export function isKnownMidLandCode(code: unknown): boolean {
  return midLandCodes.has(String(code));
}

/** 중기기온 구역 코드인지. */
export function isKnownMidTaCode(code: unknown): boolean {
  return midTaCodes.has(String(code));
}
