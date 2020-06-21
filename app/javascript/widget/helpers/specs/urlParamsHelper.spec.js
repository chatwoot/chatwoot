import { buildSearchParamsWithLocale } from '../urlParamsHelper';

jest.mock('../../i18n', () => ({
  locale: 'el',
}));

describe('#buildSearchParamsWithLocale', () => {
  it('returns correct search params', () => {
    expect(buildSearchParamsWithLocale('?test=1234')).toEqual(
      '?test=1234&locale=el'
    );
    expect(buildSearchParamsWithLocale('')).toEqual('?locale=el');
  });
});
