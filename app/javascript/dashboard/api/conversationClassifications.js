/* global axios */
import ApiClient from './ApiClient';

class ConversationClassificationsAPI extends ApiClient {
  constructor() {
    super('conversation_classifications', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  create(params) {
    return axios.post(this.url, { conversation_classification: params });
  }

  update(id, params) {
    return axios.patch(`${this.url}/${id}`, {
      conversation_classification: params,
    });
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export default new ConversationClassificationsAPI();
