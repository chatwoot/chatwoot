import { getUserCookieName } from '../cookieHelpers';

describe('#getUserCookieName', () => {
  it('returns correct cookie name', () => {
    global.$chatwoot = { websiteToken: '123456' };
    expect(getUserCookieName()).toBe('cw_user_123456');
  });
});
