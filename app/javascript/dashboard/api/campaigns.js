/* global axios */
import ApiClient from './ApiClient';

class CampaignsAPI extends ApiClient {
  constructor() {
    super('campaigns', { accountScoped: true });
  }

  getAudienceCount(labelIds) {
    return axios.get(`${this.url}/audience_count`, {
      params: { label_ids: labelIds },
    });
  }
}

export default new CampaignsAPI();
