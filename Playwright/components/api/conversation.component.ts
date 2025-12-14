import { RequestHandler } from '@utils/request-handler';

export class ConversationComponent {
  private accountId: number;

  constructor(accountId: number = 2) {
    this.accountId = accountId;
  }

  async listConversations(
    api: RequestHandler,
    apiAccessToken: string,
    filters?: {
      status?: 'open' | 'resolved' | 'pending' | 'snoozed';
      assigneeType?: 'me' | 'unassigned' | 'all';
      inboxId?: number;
    }
  ) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/conversations`)
      .headers({ 'api_access_token': apiAccessToken })
      .params(filters || {})
      .getRequest(200);

    return response;
  }

  async getConversationById(
    api: RequestHandler,
    apiAccessToken: string,
    conversationId: number
  ) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/conversations/${conversationId}`)
      .headers({ 'api_access_token': apiAccessToken })
      .getRequest(200);

    return response;
  }

  async createMessage(
    api: RequestHandler,
    apiAccessToken: string,
    conversationId: number,
    messageData: {
      content: string;
      messageType?: 'incoming' | 'outgoing';
      private?: boolean;
      contentType?: 'text' | 'input_email';
      contentAttributes?: Record<string, any>;
    }
  ) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/conversations/${conversationId}/messages`)
      .headers({
        'api_access_token': apiAccessToken,
        'Content-Type': 'application/json',
      })
      .body({
        content: messageData.content,
        message_type: messageData.messageType || 'outgoing',
        private: messageData.private || false,
        content_type: messageData.contentType || 'text',
        content_attributes: messageData.contentAttributes || {},
      })
      .postRequest(200);

    return response;
  }

  async getMessages(
    api: RequestHandler,
    apiAccessToken: string,
    conversationId: number
  ) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/conversations/${conversationId}/messages`)
      .headers({ 'api_access_token': apiAccessToken })
      .getRequest(200);

    return response;
  }

  async assignConversation(
    api: RequestHandler,
    apiAccessToken: string,
    conversationId: number,
    agentId: number
  ) {
    const response = await api
      .logs(true)
      .path(`/api/v1/accounts/${this.accountId}/conversations/${conversationId}/assignments`)
      .headers({
        'api_access_token': apiAccessToken,
        'Content-Type': 'application/json',
      })
      .body({
        assignee_id: agentId,
      })
      .postRequest(200);

    return response;
  }
}
