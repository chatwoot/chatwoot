import { getUserString, hasUserKeys } from '../../packs/sdk';

describe('#getUserString', () => {
  it('returns correct user string', () => {
    expect(
      getUserString({
        user: {
          name: 'Pranav',
          email: 'pranav@example.com',
          avatar_url: 'https://images.chatwoot.com/placeholder',
          identifier_hash: '12345',
        },
        identifier: '12345',
      })
    ).toBe(
      'avatar_urlhttps://images.chatwoot.com/placeholderemailpranav@example.comnamePranavidentifier_hash12345identifier12345'
    );

    expect(
      getUserString({
        user: {
          email: 'pranav@example.com',
          avatar_url: 'https://images.chatwoot.com/placeholder',
        },
      })
    ).toBe(
      'avatar_urlhttps://images.chatwoot.com/placeholderemailpranav@example.comnameidentifier_hashidentifier'
    );
  });
});

describe('#hasUserKeys', () => {
  it('checks whether the allowed list of keys are present', () => {
    expect(hasUserKeys({})).toBe(false);
    expect(hasUserKeys({ randomKey: 'randomValue' })).toBe(false);
    expect(hasUserKeys({ avatar_url: 'randomValue' })).toBe(true);
  });
});
