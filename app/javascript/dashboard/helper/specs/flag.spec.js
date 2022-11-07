import { getCountryFlag } from '../flag';

describe('#flag', () => {
  it('returns the correct flag ', () => {
    expect(getCountryFlag('cz')).toBe('🇨🇿');
    expect(getCountryFlag('IN')).toBe('🇮🇳');
    expect(getCountryFlag('US')).toBe('🇺🇸');
  });
});
