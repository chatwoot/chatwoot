/* global axios */
import ApiClient from './ApiClient';

class WhatsappTemplatesAPI extends ApiClient {
  constructor() {
    super('whatsapp/inboxes', { accountScoped: true });
  }

  getTemplates(inboxId) {
    return axios.get(`${this.url}/${inboxId}/message_templates`);
  }

  uploadMedia(inboxId, file) {
    const formData = new FormData();
    formData.append('file', file);
    return axios.post(
      `${this.url}/${inboxId}/message_templates/upload_media`,
      formData
    );
  }

  createTemplate(inboxId, templateData) {
    return axios.post(`${this.url}/${inboxId}/message_templates`, templateData);
  }

  deleteTemplate(inboxId, templateName) {
    return axios.delete(
      `${this.url}/${inboxId}/message_templates/${templateName}`
    );
  }
}

export default new WhatsappTemplatesAPI();
