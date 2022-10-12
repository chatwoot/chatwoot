import PortalsAPI from '../helpCenter/portals';
import ApiClient from '../ApiClient';
const portalAPI = new PortalsAPI();
describe('#PortalAPI', () => {
  it('creates correct instance', () => {
    expect(portalAPI).toBeInstanceOf(ApiClient);
    expect(portalAPI).toHaveProperty('get');
    expect(portalAPI).toHaveProperty('show');
    expect(portalAPI).toHaveProperty('create');
    expect(portalAPI).toHaveProperty('update');
    expect(portalAPI).toHaveProperty('delete');
  });
});
