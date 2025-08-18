import { getMatchingLocale } from 'shared/helpers/portalHelper';

describe('portalHelper - getMatchingLocale', () => {
  it('returns exact match when present', () => {
    const result = getMatchingLocale('fr', ['en', 'fr']);
    expect(result).toBe('fr');
  });

  it('returns base language match when exact variant not present', () => {
    const result = getMatchingLocale('fr_CA', ['en', 'fr']);
    expect(result).toBe('fr');
  });

  it('returns variant match when base language not present', () => {
    const result = getMatchingLocale('fr', ['en', 'fr_BE']);
    expect(result).toBe('fr_BE');
  });

  it('returns null when no match found', () => {
    const result = getMatchingLocale('de', ['en', 'fr']);
    expect(result).toBeNull();
  });

  it('returns null for invalid inputs', () => {
    expect(getMatchingLocale('', [])).toBeNull();
    expect(getMatchingLocale(null, null)).toBeNull();
  });
});
