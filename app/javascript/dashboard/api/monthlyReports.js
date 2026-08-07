/* global axios */
import ApiClient from './ApiClient';

class MonthlyReportsAPI extends ApiClient {
  constructor() {
    super('synapseos/monthly_reports', { accountScoped: true });
  }

  list() {
    return axios.get(this.url);
  }

  // Baixa o HTML renderizado (via axios pra levar o header de auth) como blob.
  download(id) {
    return axios.get(`${this.url}/${id}/download`, { responseType: 'blob' });
  }
}

export default new MonthlyReportsAPI();
