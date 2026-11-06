import { RequestHandler } from '@utils/request-handler';

export class PublicInboxComponent {
  private baseUrl: string;

  constructor(baseUrl: string = process.env.BASE_URL || 'http://localhost:3000') {
    this.baseUrl = baseUrl;
  }

  async createContact(
    api: RequestHandler,
    inboxIdentifier: string,
    contactData: {
      sourceId: string;
      name: string;
      email: string;
      phoneNumber?: string;
      customAttributes?: Record<string, any>;
    }
  ) {
    const response = await api
      .logs(true)
      .url(this.baseUrl)
      .path(`/public/api/v1/inboxes/${inboxIdentifier}/contacts`)
      .headers({ 'Content-Type': 'application/json' })
      .body({
        source_id: contactData.sourceId,
        name: contactData.name,
        email: contactData.email,
        phone_number: contactData.phoneNumber || '',
        custom_attributes: contactData.customAttributes || {},
      })
      .postRequest(200);

    return response;
  }

  async createConversation(
    api: RequestHandler,
    inboxIdentifier: string,
    sourceId: string,
    customAttributes?: Record<string, any>
  ) {
    const response = await api
      .logs(true)
      .url(this.baseUrl)
      .path(`/public/api/v1/inboxes/${inboxIdentifier}/contacts/${sourceId}/conversations`)
      .headers({ 'Content-Type': 'application/json' })
      .body({
        custom_attributes: customAttributes || {},
      })
      .postRequest(200);

    return response;
  }

  async createMessage(
    api: RequestHandler,
    inboxIdentifier: string,
    sourceId: string,
    conversationId: number,
    messageData: {
      content: string;
      echoId?: string;
    }
  ) {
    const response = await api
      .logs(true)
      .url(this.baseUrl)
      .path(`/public/api/v1/inboxes/${inboxIdentifier}/contacts/${sourceId}/conversations/${conversationId}/messages`)
      .headers({ 'Content-Type': 'application/json' })
      .body({
        content: messageData.content,
        echo_id: messageData.echoId || '',
      })
      .postRequest(200);

    return response;
  }
}
