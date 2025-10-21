import ApiClient from './ApiClient';

class PipelineStatusesAPI extends ApiClient {
  constructor() {
    super('pipeline_statuses', { accountScoped: true });
  }
}

export default new PipelineStatusesAPI();
