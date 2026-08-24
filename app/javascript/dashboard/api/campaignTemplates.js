/* global axios */
import ApiClient from './ApiClient';

class CampaignTemplatesAPI extends ApiClient {
  constructor() {
    super('campaign_templates', { accountScoped: true });
  }

  create(data) {
    return axios.post(this.url, { campaign_template: data });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, { campaign_template: data });
  }
}

export default new CampaignTemplatesAPI();
