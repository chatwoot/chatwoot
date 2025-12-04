/* global axios */
import ApiClient from './ApiClient';

class EmailTemplatesAPI extends ApiClient {
  constructor() {
    super('email_templates', { accountScoped: true });
  }

  activate(id) {
    return axios.post(`${this.url}/${id}/activate`);
  }

  deactivate(id) {
    return axios.post(`${this.url}/${id}/deactivate`);
  }
}

export default new EmailTemplatesAPI();
