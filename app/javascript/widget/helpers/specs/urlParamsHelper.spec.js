import {
  buildSearchParamsWithLocale,
  getLocale,
  buildPopoutURL,
  getArticleViewerURL,
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

describe('#buildPopoutURL', () => {
  it('returns popout URL', () => {
    expect(
      buildPopoutURL({
        origin: 'https://chatwoot.com',
        conversationCookie: 'random-jwt-token',
        websiteToken: 'random-website-token',
        locale: 'ar',
      })
    ).toEqual(
      'https://chatwoot.com/widget?cw_conversation=random-jwt-token&website_token=random-website-token&locale=ar'
    );
  });
});

describe('#getArticleViewerURL', () => {
  const origin = 'https://app.chatwoot.com';

  it.each([
    [
      'hc/docs/articles/intro?show_plain_layout=true',
      'https://app.chatwoot.com/hc/docs/articles/intro?show_plain_layout=true',
    ],
    [
      '/hc/docs/en?theme=dark',
      'https://app.chatwoot.com/hc/docs/en?theme=dark',
    ],
    [
      'https://app.chatwoot.com/hc/docs/en',
      'https://app.chatwoot.com/hc/docs/en',
    ],
  ])('returns the URL for %s', (link, expected) => {
    expect(getArticleViewerURL(link, origin)).toEqual(expected);
  });

  it.each([
    // eslint-disable-next-line no-script-url
    'javascript:alert(1)//?show_plain_layout=true',
    'data:text/html,hello',
    'https://example.com/hc/docs/en',
    '//example.com/hc/docs/en',
    '/hc/../widget',
    '/widget',
    '',
    undefined,
    ['/hc/docs/en'],
  ])('returns an empty string for %s', link => {
    expect(getArticleViewerURL(link, origin)).toEqual('');
  });
});
