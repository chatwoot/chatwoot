import {
  buildSearchParamsWithLocale,
  getLocale,
  buildPopoutURL,
  looksLikeJwt,
  stripConversationToken,
} from '../urlParamsHelper';

describe('#buildSearchParamsWithLocale', () => {
  it('returns correct search params', () => {
    let windowSpy = vi.spyOn(window, 'window', 'get');
    windowSpy.mockImplementation(() => ({
      WOOT_WIDGET: {
        $root: {
          $i18n: {
            locale: 'el',
          },
        },
      },
    }));
    expect(buildSearchParamsWithLocale('?test=1234')).toEqual(
      '?test=1234&locale=el'
    );
    expect(buildSearchParamsWithLocale('')).toEqual('?locale=el');
    expect(
      buildSearchParamsWithLocale(
        '?website_token=abc&cw_conversation=jwt.token'
      )
    ).toEqual('?website_token=abc&locale=el');
    windowSpy.mockRestore();
  });
});

describe('#getLocale', () => {
  it('returns correct locale', () => {
    expect(getLocale('?test=1&cw_conv=2&locale=fr')).toEqual('fr');
    expect(getLocale('?test=1&locale=fr')).toEqual('fr');
    expect(getLocale('?test=1&cw_conv=2&website_token=3&locale=fr')).toEqual(
      'fr'
    );
    expect(getLocale('')).toEqual(null);
  });
});

describe('#looksLikeJwt', () => {
  it('accepts a three-part token and rejects junk', () => {
    expect(looksLikeJwt('aaa.bbb.ccc')).toEqual(true);
    expect(looksLikeJwt('not-a-jwt')).toEqual(false);
    expect(looksLikeJwt('')).toEqual(false);
  });
});

describe('#stripConversationToken', () => {
  it('removes cw_conversation from the query string', () => {
    expect(
      stripConversationToken('?website_token=abc&cw_conversation=jwt.token')
    ).toEqual('?website_token=abc');
    expect(stripConversationToken('?cw_conversation=jwt.token')).toEqual('');
    expect(stripConversationToken('')).toEqual('');
  });
});

describe('#buildPopoutURL', () => {
  it('returns popout URL without the session JWT', () => {
    expect(
      buildPopoutURL({
        origin: 'https://chatwoot.com',
        conversationCookie: 'random-jwt-token',
        websiteToken: 'random-website-token',
        locale: 'ar',
      })
    ).toEqual(
      'https://chatwoot.com/widget?website_token=random-website-token&locale=ar'
    );
  });
});
