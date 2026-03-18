/* global axios */
import ApiClient from './ApiClient';

class PipelineStatusesAPI extends ApiClient {
  constructor() {
    super('pipeline_statuses', { accountScoped: true });
  }

  reorder(orderedIds) {
    return axios.post(`${this.url}/reorder`, { ordered_ids: orderedIds });
  }
}

export default new PipelineStatusesAPI();
