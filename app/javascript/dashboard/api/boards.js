/* global axios */
import ApiClient from './ApiClient';

class BoardsAPI extends ApiClient {
  constructor() {
    super('sales_pipelines/boards', { accountScoped: true });
  }

  search(stageType) {
    return axios.get(`${this.url}/search?stage_type=${stageType}`);
  }
}

export default new BoardsAPI();
