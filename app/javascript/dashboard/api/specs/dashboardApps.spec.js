import dashboardAppsAPI from '../dashboardApps';
import ApiClient from '../ApiClient';

describe('#dashboardAppsAPI', () => {
  it('creates correct instance', () => {
    expect(dashboardAppsAPI).toBeInstanceOf(ApiClient);
    expect(dashboardAppsAPI).toHaveProperty('get');
    expect(dashboardAppsAPI).toHaveProperty('show');
    expect(dashboardAppsAPI).toHaveProperty('create');
    expect(dashboardAppsAPI).toHaveProperty('update');
    expect(dashboardAppsAPI).toHaveProperty('delete');
  });
});
