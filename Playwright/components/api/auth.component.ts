import { request } from '@playwright/test';
import { RequestHandler } from '@utils/request-handler';
import { APILogger } from '@utils/logger';

export class AuthComponent {
  private baseUrl: string;

  constructor(baseUrl: string = process.env.BASE_URL || 'http://localhost:3000') {
    this.baseUrl = baseUrl;
  }

  async login(email: string, password: string, retries: number = 3) {
    const context = await request.newContext();
    const logger = new APILogger();
    const api = new RequestHandler(context, this.baseUrl, logger);

    let lastError;
    let attempts = retries;

    while (attempts > 0) {
      try {
        const { headers } = await api
          .logs(true)
          .url(this.baseUrl)
          .path('/auth/sign_in')
          .headers({
            'Content-Type': 'application/json',
            'Accept': 'application/json, text/plain, */*',
          })
          .body({
            email: email,
            password: password,
            sso_auth_token: '',
          })
          .postRequestWithHeaders(200);

        await context.dispose();

        return {
          'access-token': headers['access-token'],
          client: headers['client'],
          uid: headers['uid'],
        };
      } catch (error: any) {
        lastError = error;
        if (error.message?.includes('429')) {
          attempts--;
          if (attempts > 0) {
            const waitTime = (retries - attempts) * 5000;
            console.log(`Rate limited (429), waiting ${waitTime/1000}s before retry...`);
            await new Promise(resolve => setTimeout(resolve, waitTime));
          }
        } else {
          await context.dispose();
          throw error;
        }
      }
    }

    await context.dispose();
    throw new Error(`Failed to login after ${retries} retries: ${lastError?.message}`);
  }

  async logout(authHeaders: Record<string, string>, api: RequestHandler) {
    const logoutResponse = await api
      .logs(true)
      .url(this.baseUrl)
      .path('/auth/sign_out')
      .headers({
        'access-token': authHeaders['access-token'],
        client: authHeaders['client'],
        uid: authHeaders['uid'],
        'Content-Type': 'application/json',
      })
      .deleteRequest(200);

    return logoutResponse;
  }
}
