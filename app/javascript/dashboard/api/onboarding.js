/* global axios */
import ApiClient from './ApiClient';

class OnboardingAPI extends ApiClient {
  constructor() {
    super('onboarding', { accountScoped: true });
  }

  update(data) {
    return axios.patch(this.url, data);
  }
}

export default new OnboardingAPI();
