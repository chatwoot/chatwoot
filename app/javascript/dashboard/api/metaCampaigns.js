/* global axios */
import ApiClient from './ApiClient';

class MetaCampaignsAPI extends ApiClient {
  constructor() {
    super('meta_campaign_reports', { accountScoped: true, apiVersion: 'v2' });
  }

  getCampaigns(params) {
    return axios.get(this.url, { params });
  }

  getCampaignDetails(sourceId, params) {
    return axios.get(`${this.url}/${sourceId}`, { params });
  }

  getSummary(params) {
    return axios.get(`${this.url}/summary`, { params });
  }
}

export default new MetaCampaignsAPI();
