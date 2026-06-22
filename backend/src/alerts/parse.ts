/**
 * lib/data/alert/alert_repository.dart의 _cleanAlertText/_parseTmFc와 동일한 로직.
 * 두 구현이 갈라지면 안 되므로, 한쪽을 고치면 반드시 다른 쪽도 맞춰야 한다.
 */

/** "o 없음"(중간 공백·개행 변형 포함)이면 빈 문자열로, 아니면 정리한 본문. */
export function cleanAlertText(raw: string | null | undefined): string {
  if (!raw) return '';
  const normalized = raw.replace(/\r\n/g, '\n').trim();
  const compact = normalized.replace(/\s/g, '');
  const withoutBullet = compact.replace(/^[oㅇO]/, '');
  if (withoutBullet === '없음' || withoutBullet === '') return '';
  return normalized;
}

/** yyyyMMddHHmm(숫자) → Date(KST). 형식이 안 맞으면 null. */
export function parseTmFc(tmFc: number | null | undefined): Date | null {
  if (tmFc == null) return null;
  const s = String(tmFc);
  if (s.length !== 12) return null;
  const year = Number(s.slice(0, 4));
  const month = Number(s.slice(4, 6));
  const day = Number(s.slice(6, 8));
  const hour = Number(s.slice(8, 10));
  const minute = Number(s.slice(10, 12));
  // KMA 시각은 KST(UTC+9) 기준. UTC로 명시 계산해 서버 타임존에 의존하지 않는다.
  return new Date(Date.UTC(year, month - 1, day, hour - 9, minute));
}

/** UTC 필드를 그대로 yyyyMMdd로 포맷. KST 날짜가 필요하면 nowKst()를 넘길 것. */
export function ymd(date: Date): string {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  const d = String(date.getUTCDate()).padStart(2, '0');
  return `${y}${m}${d}`;
}

/**
 * 서버가 어느 타임존에서 돌든(Render는 보통 UTC) KST 달력 날짜를 얻기 위한 트릭:
 * 실제 UTC 시각에 9시간을 더한 뒤 getUTC*로 읽으면 KST의 연/월/일이 그대로 나온다.
 * (절대 시각 비교에는 쓰지 말 것 — 달력 날짜 추출 전용.)
 */
export function nowKst(): Date {
  return new Date(Date.now() + 9 * 60 * 60 * 1000);
}
