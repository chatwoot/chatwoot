import { RequestHandler } from '@utils/request-handler';

export class InboxComponent {
  private accountId: number;

  constructor(accountId: number = 2) {
    this.accountId = accountId;
  }

  async createApiInbox(
    api: RequestHandler,
    authHeaders: Record<string, string>,
    inboxData: {
      name: string;
      webhookUrl?: string;
      hmacMandatory?: boolean;
    }
  ) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/inboxes`)
      .headers({ ...authHeaders, 'Content-Type': 'application/json' })
      .body({
        name: inboxData.name,
        channel: {
          type: 'api',
          webhook_url: inboxData.webhookUrl || '',
          hmac_mandatory: inboxData.hmacMandatory || false,
        },
      })
      .postRequest(200);

    return response;
  }

  async createWebsiteInbox(
    api: RequestHandler,
    authHeaders: Record<string, string>,
    inboxData: {
      name: string;
      websiteUrl: string;
      widgetColor?: string;
      welcomeTitle?: string;
      welcomeTagline?: string;
      greetingEnabled?: boolean;
      greetingMessage?: string;
    }
  ) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/inboxes`)
      .headers({ ...authHeaders, 'Content-Type': 'application/json' })
      .body({
        name: inboxData.name,
        channel: {
          type: 'web_widget',
          website_url: inboxData.websiteUrl,
          widget_color: inboxData.widgetColor || '#009CE0',
          welcome_title: inboxData.welcomeTitle || '',
          welcome_tagline: inboxData.welcomeTagline || '',
        },
        greeting_enabled: inboxData.greetingEnabled || false,
        greeting_message: inboxData.greetingMessage || '',
      })
      .postRequest(200);

    return response;
  }

  async getInboxList(api: RequestHandler, authHeaders: Record<string, string>) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/inboxes`)
      .headers(authHeaders)
      .getRequest(200);

    return response;
  }

  async getInboxById(api: RequestHandler, authHeaders: Record<string, string>, inboxId: number) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/inboxes/${inboxId}`)
      .headers(authHeaders)
      .getRequest(200);

    return response;
  }

  async deleteInbox(api: RequestHandler, authHeaders: Record<string, string>, inboxId: number) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/inboxes/${inboxId}`)
      .headers({ ...authHeaders, 'Content-Type': 'application/json' })
      .deleteRequest(200);

    return response;
  }

  async addAgentToInbox(
    api: RequestHandler,
    authHeaders: Record<string, string>,
    inboxId: number,
    agentIds: number[]
  ) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/inbox_members`)
      .headers({ ...authHeaders, 'Content-Type': 'application/json' })
      .body({
        inbox_id: inboxId,
        user_ids: agentIds,
      })
      .postRequest(200);

    return response;
  }
}
