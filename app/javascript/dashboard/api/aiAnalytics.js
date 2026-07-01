import ApiClient from './ApiClient';

class AiAnalyticsAPI extends ApiClient {
  constructor() {
    super('reports/ai_analytics_query', { apiVersion: 'v2' });
  }

  query(queryText) {
    return this.axios.post(this.url, { query: queryText });
  }
}

export default new AiAnalyticsAPI();
