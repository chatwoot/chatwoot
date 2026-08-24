import ApiClient from './ApiClient';

class WhatsappTopupRequests extends ApiClient {
  constructor() {
    super('whatsapp_topup_requests', { accountScoped: true });
  }
}

export default new WhatsappTopupRequests();
