/* global axios */
import ApiClient from './ApiClient';

class StageAPI extends ApiClient {
  constructor() {
    super('stages', { accountScoped: true });
  }

  getStagesByType() {
    return axios.get(this.url);
  }
}

export default new StageAPI();
