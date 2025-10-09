import ApiClient from './ApiClient';

class MarketingCampaigns extends ApiClient {
  constructor() {
    super('marketing_campaigns', { accountScoped: true });
  }
}

export default new MarketingCampaigns();
