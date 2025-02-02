/* global axios */
import ApiClient from './ApiClient';

class CampaignsAPI extends ApiClient {
  constructor() {
    super('campaigns', { accountScoped: true });
  }

  fetchCampaignContacts(id) {
    return axios.get(`${this.url}/${id}/fetch_campaign_contacts`);
  }
}

export default new CampaignsAPI();
