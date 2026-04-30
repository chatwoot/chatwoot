/* global axios */
import ApiClient from './ApiClient';

class PipelineStatusesAPI extends ApiClient {
  constructor() {
    super('pipeline_statuses', { accountScoped: true });
  }

  getByType(pipelineType) {
    return axios.get(`${this.url}?pipeline_type=${pipelineType}`);
  }

  reorder(orderedIds) {
    return axios.post(`${this.url}/reorder`, { ordered_ids: orderedIds });
  }

  getBoard(params = {}) {
    return axios.post(`${this.url}/board`, params);
  }

  getColumnItems(params = {}) {
    return axios.post(`${this.url}/column_items`, params);
  }
}

export default new PipelineStatusesAPI();
