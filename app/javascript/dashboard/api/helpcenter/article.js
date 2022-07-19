import ApiClient from '../ApiClient';

class HelpCenterPortalArticlesAPI extends ApiClient {
  constructor() {
    super('articles', { accountScoped: true });
  }
}

export default new HelpCenterPortalArticlesAPI();
