import { RequestHandler } from '@utils/request-handler';

export class AgentComponent {
  private accountId: number;

  constructor(accountId: number = 2) {
    this.accountId = accountId;
  }

  async create(api: RequestHandler, authHeaders: Record<string, string>, agentData: { name: string; email: string; role: string }) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/agents`)
      .headers({
        ...authHeaders,
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/plain, */*',
      })
      .body({
        name: agentData.name,
        email: agentData.email,
        role: agentData.role,
      })
      .postRequest(200);

    return response;
  }
}
