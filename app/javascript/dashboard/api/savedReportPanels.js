/* global axios */
import ApiClient from './ApiClient';

class SavedReportPanelsAPI extends ApiClient {
  constructor() {
    super('saved_report_panels', { accountScoped: true });
  }

  run(id, params = {}) {
    return axios.post(`${this.url}/${id}/run`, params);
  }

  export(id, params = {}) {
    return axios.get(`${this.url}/${id}/export`, {
      params,
      responseType: 'blob',
    });
  }
}

export default new SavedReportPanelsAPI();
