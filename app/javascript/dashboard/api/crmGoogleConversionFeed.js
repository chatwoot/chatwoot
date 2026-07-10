/* global axios */
import ApiClient from './ApiClient';

class CrmGoogleConversionFeedAPI extends ApiClient {
  constructor() {
    super('crm/google_conversion_feed', { accountScoped: true });
  }

  create() {
    return axios.post(this.url);
  }
}

export default new CrmGoogleConversionFeedAPI();
