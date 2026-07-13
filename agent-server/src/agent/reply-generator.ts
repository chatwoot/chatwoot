import type { ChatwootWebhookPayload } from '../chatwoot/types.js';

export type ReplyRequest = {
  content: string;
  conversationId: number;
  payload: ChatwootWebhookPayload;
};

export interface ReplyGenerator {
  generate(request: ReplyRequest): Promise<string>;
}

export class EchoReplyGenerator implements ReplyGenerator {
  async generate(request: ReplyRequest): Promise<string> {
    return `확인했습니다. 다음 메시지를 수신했습니다: ${request.content}`;
  }
}
