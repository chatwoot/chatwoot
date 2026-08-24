import ApiClient from './ApiClient';

class WhatsappUsage extends ApiClient {
  constructor() {
    super('whatsapp_usage', { accountScoped: true });
  }
}

export default new WhatsappUsage();
