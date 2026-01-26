/* global axios */
import ApiClient from './ApiClient';

class NotionAPI extends ApiClient {
  constructor() {
    super('notion/databases', { accountScoped: true });
  }

  listDatabases() {
    return this.get();
  }

  getDatabaseSchema(databaseId) {
    return this.show(databaseId);
  }

  queryDatabase(databaseId, filters = {}) {
    return axios.post(`${this.url}/${databaseId}/query`, filters);
  }
}

export default new NotionAPI();
