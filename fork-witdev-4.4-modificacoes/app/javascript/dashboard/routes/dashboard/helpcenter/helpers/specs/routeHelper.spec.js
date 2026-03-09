import { getPortalRoute } from '../routeHelper';

describe('', () => {
  it('returns correct portal URL', () => {
    expect(getPortalRoute('')).toEqual('/app/accounts/:accountId/portals');
    expect(getPortalRoute(':portalSlug')).toEqual(
      '/app/accounts/:accountId/portals/:portalSlug'
    );
  });
});
