import fs from 'node:fs';
import path from 'node:path';

import { initializeApp, getApps, getApp, type App } from 'firebase-admin/app';
import { cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

/**
 * 서비스 계정 키를 로드한다.
 * - 배포 환경: FIREBASE_SERVICE_ACCOUNT 환경변수에 JSON 전체를 한 줄로 넣음
 * - 로컬 개발: 비워두면 backend/.secrets/service-account.json 파일을 읽음(gitignore됨)
 */
function loadServiceAccount(): Record<string, unknown> {
  const inline = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (inline) {
    return JSON.parse(inline);
  }

  const localPath = path.resolve(__dirname, '..', '..', '.secrets', 'service-account.json');
  if (fs.existsSync(localPath)) {
    return JSON.parse(fs.readFileSync(localPath, 'utf8'));
  }

  throw new Error(
    'Firebase 서비스 계정 키를 찾을 수 없습니다. FIREBASE_SERVICE_ACCOUNT 환경변수를 설정하거나 ' +
      'backend/.secrets/service-account.json에 키 파일을 두세요.',
  );
}

export function getFirebaseApp(): App {
  // Firebase Functions 런타임에선 진입점(functions/src/index.ts)이 initializeApp()을
  // 먼저 호출해 기본 앱이 이미 존재한다 — 그 앱을 재사용한다(자격증명 자동 = ADC).
  // Render 등 그 외 환경에선 기본 앱이 없으므로 서비스 계정 키로 초기화한다.
  if (getApps().length > 0) {
    return getApp();
  }
  return initializeApp({ credential: cert(loadServiceAccount() as never) });
}

/** 특정 관서 토픽 구독자 전체에게 특보 푸시를 보낸다. */
export async function sendAlertPush(topic: string, title: string, body: string): Promise<string> {
  const messaging = getMessaging(getFirebaseApp());
  return messaging.send({
    topic,
    notification: { title, body },
  });
}
