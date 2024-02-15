import { getBrowserLocale, getBrowserTimezone } from '../BrowserHelper';

describe('getBrowserLocale', () => {
  it('should return the correct locale code when an exact match is found', () => {
    // Mock window.navigator.language
    Object.defineProperty(window.navigator, 'language', {
      value: 'en-US',
      configurable: true,
    });

    const languages = [{ iso_639_1_code: 'en' }, { iso_639_1_code: 'en_US' }];
    expect(getBrowserLocale(languages)).toBe('en');
  });

  it('should return the correct locale code when only a partial match is found', () => {
    Object.defineProperty(window.navigator, 'language', {
      value: 'en-GB',
      configurable: true,
    });

    const languages = [{ iso_639_1_code: 'en' }, { iso_639_1_code: 'fr' }];
    expect(getBrowserLocale(languages)).toBe('en');
  });

  it('should return undefined when no match is found', () => {
    Object.defineProperty(window.navigator, 'language', {
      value: 'es-ES',
      configurable: true,
    });

    const languages = [{ iso_639_1_code: 'en' }, { iso_639_1_code: 'fr' }];
    expect(getBrowserLocale(languages)).toBeUndefined();
  });
});

describe('getBrowserTimezone', () => {
  it('should return the current browser timezone', () => {
    // This test assumes the environment's timezone is set.
    // It's a basic test as getBrowserTimezone relies on Intl API.
    const timezone = getBrowserTimezone();
    expect(timezone).toBe(Intl.DateTimeFormat().resolvedOptions().timeZone);
  });
});
