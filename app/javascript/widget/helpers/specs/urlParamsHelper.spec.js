import { buildSearchParamsWithLocale, getLocale } from '../urlParamsHelper';

jest.mock('vue', () => ({
  config: {
    lang: 'el',
  },
}));

describe('#buildSearchParamsWithLocale', () => {
  it('returns correct search params', () => {
    expect(buildSearchParamsWithLocale('?test=1234')).toEqual(
      '?test=1234&locale=el'
    );
    expect(buildSearchParamsWithLocale('')).toEqual('?locale=el');
  });
});

describe('#getLocale', () => {
  it('returns correct locale', () => {
    expect(getLocale('?test=1&cw_conv=2&locale=fr')).toEqual('fr');
    expect(getLocale('?test=1&locale=fr')).toEqual('fr');
    expect(getLocale('?test=1&cw_conv=2&website_token=3&locale=fr')).toEqual(
      'fr'
    );
    expect(getLocale('')).toEqual(undefined);
  });
});
