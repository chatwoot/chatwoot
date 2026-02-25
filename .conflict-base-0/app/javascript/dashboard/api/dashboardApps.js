import ApiClient from './ApiClient';

class DashboardAppsAPI extends ApiClient {
  constructor() {
    super('dashboard_apps', { accountScoped: true });
  }
}

export default new DashboardAppsAPI();
