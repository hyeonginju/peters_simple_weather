import fs from 'node:fs';
import path from 'node:path';

// 로컬 개발용 .env 로드(있을 때만). 배포 환경에선 플랫폼이 환경변수를 주입한다.
loadDotEnvIfPresent();

export const config = {
  kmaServiceKey: requireEnv('KMA_SERVICE_KEY'),
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
