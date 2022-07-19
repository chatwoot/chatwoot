import ApiClient from '../ApiClient';

class HelpCenterPortalsAPI extends ApiClient {
  constructor() {
    super('portals', { accountScoped: true });
  }
}

export default new HelpCenterPortalsAPI();
