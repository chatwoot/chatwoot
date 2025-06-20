/* global axios */
import ApiClient from './ApiClient';

class PromptAPI extends ApiClient {
  constructor() {
    super('prompts', { accountScoped: true, apiVersion: 'v2' });
  }

  get() {
    return axios.get(this.url);
  }

  create(promptData) {
    return axios.post(this.url, promptData);
  }

  update(id, promptData) {
    return axios.patch(`${this.url}/${id}`, promptData);
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export default new PromptAPI();
