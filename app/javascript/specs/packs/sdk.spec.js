import { getUserCookieName, getUserString } from '../../packs/sdk';

describe('#getUserCookieName', () => {
  it('returns correct cookie name', () => {
    global.$chatwoot = { websiteToken: '123456' };
    expect(getUserCookieName()).toBe('cw_user_123456');
  });
});

describe('#getUserString', () => {
  it('returns correct user string', () => {
    expect(
      getUserString({
        user: {
          name: 'Pranav',
          email: 'pranav@example.com',
          avatar_url: 'https://images.chatwoot.com/placeholder',
        },
        identifier: '12345',
      })
    ).toBe(
      'avatar_urlhttps://images.chatwoot.com/placeholderemailpranav@example.comnamePranavidentifier12345'
    );

    expect(
      getUserString({
        user: {
          email: 'pranav@example.com',
          avatar_url: 'https://images.chatwoot.com/placeholder',
        },
      })
    ).toBe(
      'avatar_urlhttps://images.chatwoot.com/placeholderemailpranav@example.comnameidentifier'
    );
  });
});
