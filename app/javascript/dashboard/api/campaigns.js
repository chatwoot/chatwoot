/* global axios */
import ApiClient from './ApiClient';

class CampaignsAPI extends ApiClient {
  constructor() {
    super('campaigns', { accountScoped: true });
  }

  // Kiraid: fire a one_off (cold-outreach) campaign immediately.
  trigger(id) {
    return axios.post(`${this.url}/${id}/trigger`);
  }
}

export default new CampaignsAPI();
