import ApiClient from './ApiClient';

class AutoQaAPI extends ApiClient {
  constructor() {
    super('reports/auto_qa', { apiVersion: 'v2' });
  }

  get() {
    return this.axios.get(this.url);
  }
}

export default new AutoQaAPI();
