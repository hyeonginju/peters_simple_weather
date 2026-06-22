import fs from 'node:fs';
import path from 'node:path';

import { initializeApp, type App } from 'firebase-admin/app';
import { cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

let app: App | undefined;

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

function getApp(): App {
  if (!app) {
    app = initializeApp({ credential: cert(loadServiceAccount() as never) });
  }
  return app;
}

/** 특정 관서 토픽 구독자 전체에게 특보 푸시를 보낸다. */
export async function sendAlertPush(topic: string, title: string, body: string): Promise<string> {
  const messaging = getMessaging(getApp());
  return messaging.send({
    topic,
    notification: { title, body },
  });
}
