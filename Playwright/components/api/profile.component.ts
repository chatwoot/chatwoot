import { RequestHandler } from '@utils/request-handler';

export class ProfileComponent {
  async getProfile(api: RequestHandler, authHeaders: Record<string, string>) {
    const response = await api
      .logs(true)
      .path('/api/v1/profile')
      .headers(authHeaders)
      .getRequest(200);

    return response;
  }
}
