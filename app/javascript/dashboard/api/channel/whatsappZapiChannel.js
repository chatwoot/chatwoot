import ApiClient from '../ApiClient';

class WhatsappZapiChannel extends ApiClient {
  constructor() {
    super('channels/whatsapp_zapi_channels', { accountScoped: true });
  }
}

export default new WhatsappZapiChannel();
