/* global axios */
import ApiClient from './ApiClient';

class WhatsappTemplatesAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  getTemplates(inboxId) {
    return axios.get(`${this.baseUrl()}/inboxes/${inboxId}/whatsapp_templates`);
  }

  createTemplate(inboxId, templateData) {
    return axios.post(
      `${this.baseUrl()}/inboxes/${inboxId}/whatsapp_templates`,
      { template: templateData }
    );
  }

  deleteTemplate(inboxId, templateName) {
    return axios.delete(
      `${this.baseUrl()}/inboxes/${inboxId}/whatsapp_templates/${templateName}`
    );
  }
}

export default new WhatsappTemplatesAPI();
