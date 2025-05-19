import ApiClient from './ApiClient';

class WhatsAppUnofficialChannels extends ApiClient {
  constructor() {
    super('channels/whatsapp_unofficial_channels', { accountScoped: true });
  }

  create({ phone_number, inbox_name }) {
    return axios.post(this.url, {
      phone_number,
      inbox_name,
    });
  }
}

export default new WhatsAppUnofficialChannels();
