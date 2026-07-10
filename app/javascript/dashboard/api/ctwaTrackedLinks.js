import ApiClient from './ApiClient';

class CtwaTrackedLinksAPI extends ApiClient {
  constructor() {
    super('ctwa_tracked_links', { accountScoped: true });
  }
}

export default new CtwaTrackedLinksAPI();
