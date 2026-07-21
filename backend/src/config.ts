import fs from 'node:fs';
import path from 'node:path';

// 로컬 개발용 .env 로드(있을 때만). 배포 환경에선 플랫폼이 환경변수를 주입한다.
loadDotEnvIfPresent();

// KMA 키는 lazy getter로 노출한다. 이 config 모듈은 KMA 클라이언트를 통해 폴러
// 코드에도 함께 번들되는데(Firebase Functions), 그쪽은 KMA 키가 런타임 시크릿으로
// 주입된다. 로드 시점에 강제하면 함수가 뜨질 못하므로, 실제로 값을 읽는 시점
// (요청/폴 처리 중)에만 검사한다.
export const config = {
  get kmaServiceKey(): string {
    return requireEnv('KMA_SERVICE_KEY');
  },
  port: Number(process.env.PORT) || 8080,
};

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`환경변수 ${name}가 설정되지 않았습니다. backend/.env 또는 호스팅 환경변수를 확인하세요.`);
  }
  return value;
}

/** dotenv 패키지 없이 backend/.env를 직접 파싱(KEY=VALUE 한 줄씩). */
function loadDotEnvIfPresent(): void {
  const envPath = path.resolve(__dirname, '..', '.env');
  if (!fs.existsSync(envPath)) return;

  for (const line of fs.readFileSync(envPath, 'utf8').split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq === -1) continue;
    const key = trimmed.slice(0, eq).trim();
    const value = trimmed.slice(eq + 1).trim();
    if (key && process.env[key] === undefined) {
      process.env[key] = value;
    }
  }
}
