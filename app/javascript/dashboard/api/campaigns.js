/* global axios */
import ApiClient from './ApiClient';

class CampaignsAPI extends ApiClient {
  constructor() {
    super('campaigns', { accountScoped: true });
  }

  validateZnsTemplate(campaignObj) {
    return axios.post(`${this.url}/validate_zns_template`, campaignObj);
  }
}

export default new CampaignsAPI();
