/* global axios */
import ApiClient from './ApiClient';

class WhatsappInteractiveTemplatesAPI extends ApiClient {
  constructor() {
    super('whatsapp_interactive_templates', { accountScoped: true });
  }

  publishHeader(blobId) {
    return axios.post(`${this.url}/publish_header`, { blob_id: blobId });
  }

  dispatchToConversation(templateId, conversationId, extraParams = {}) {
    return axios.post(`${this.url}/${templateId}/dispatch_to_conversation`, {
      conversation_id: conversationId,
      ...extraParams,
    });
  }
}

export default new WhatsappInteractiveTemplatesAPI();
