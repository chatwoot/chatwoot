/* global axios */
import ApiClient from '../ApiClient';

class LlmAPI extends ApiClient {
  constructor() {
    super('llm', { accountScoped: true, saas: true });
  }

  getModels() {
    return axios.get(`${this.url}/models`);
  }

  getHealth() {
    return axios.get(`${this.url}/health`);
  }
}

export default new LlmAPI();
