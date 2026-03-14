import ApiClient from './ApiClient';

class WhatsappInteractiveTemplatesAPI extends ApiClient {
  constructor() {
    super('whatsapp_interactive_templates', { accountScoped: true });
  }

  publishHeader(blobId) {
    return axios.post(`${this.url}/publish_header`, { blob_id: blobId });
  }
}

export default new WhatsappInteractiveTemplatesAPI();
