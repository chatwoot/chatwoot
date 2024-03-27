import { getBrowserLocale, getIANATimezoneFromOffset } from '../BrowserHelper';
describe('getBrowserLocale', () => {
  let languageSpy;

  afterEach(() => {
    // Restore the original implementation after each test
    languageSpy.mockRestore();
  });

  it('should return the correct locale code when an exact match is found', () => {
    languageSpy = jest
      .spyOn(navigator, 'language', 'get')
      .mockReturnValue('en-US');
    const languages = [{ iso_639_1_code: 'en' }, { iso_639_1_code: 'en_US' }];
    expect(getBrowserLocale(languages)).toBe('en');
  });

  it('should return the correct locale code when only a partial match is found', () => {
    languageSpy = jest
      .spyOn(navigator, 'language', 'get')
      .mockReturnValue('en-GB');
    const languages = [{ iso_639_1_code: 'en' }, { iso_639_1_code: 'fr' }];
    expect(getBrowserLocale(languages)).toBe('en');
  });

  it('should return undefined when no match is found', () => {
    languageSpy = jest
      .spyOn(navigator, 'language', 'get')
      .mockReturnValue('es-ES');
    const languages = [{ iso_639_1_code: 'en' }, { iso_639_1_code: 'fr' }];
    expect(getBrowserLocale(languages)).toBeUndefined();
  });
});

describe('getIANATimezoneFromOffset', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('should return the correct timezone description for GMT-8:00 offset', () => {
    jest
      .spyOn(Date.prototype, 'getTimezoneOffset')
      .mockImplementation(() => 480); // GMT-8:00
    expect(getIANATimezoneFromOffset()).toBe('America/Juneau'); // Adjusted expectation
  });

  it('should return the correct timezone description for GMT+2:00 offset', () => {
    jest
      .spyOn(Date.prototype, 'getTimezoneOffset')
      .mockImplementation(() => -120); // GMT+2:00
    expect(getIANATimezoneFromOffset()).toBe('Europe/Belgrade'); // Adjusted expectation
  });
  // Half-hour offsets
  it('should return the correct timezone description for GMT+5:30 offset', () => {
    jest
      .spyOn(Date.prototype, 'getTimezoneOffset')
      .mockImplementation(() => -330); // GMT+5:30
    expect(getIANATimezoneFromOffset()).toBe('Asia/Kolkata'); // Updated expectation
  });

  it('should return the correct timezone description for GMT+9:30 offset', () => {
    jest
      .spyOn(Date.prototype, 'getTimezoneOffset')
      .mockImplementation(() => -570); // GMT+9:30
    expect(getIANATimezoneFromOffset()).toBe('Australia/Darwin'); // Updated expectation
  });

  // Quarter-hour offsets
  it('should return the correct timezone description for GMT+5:45 offset', () => {
    jest
      .spyOn(Date.prototype, 'getTimezoneOffset')
      .mockImplementation(() => -345); // GMT+5:45
    expect(getIANATimezoneFromOffset()).toBe('Asia/Kathmandu'); // Updated expectation
  });

  // Edge cases
  it('should return the correct timezone description for GMT+0:00 offset', () => {
    jest.spyOn(Date.prototype, 'getTimezoneOffset').mockImplementation(() => 0); // GMT+0:00
    expect(getIANATimezoneFromOffset()).toBe('Africa/Monrovia'); // Adjusted expectation
  });
  // Unrecognized offset
  it('should return undefined for an unrecognized GMT offset', () => {
    jest
      .spyOn(Date.prototype, 'getTimezoneOffset')
      .mockImplementation(() => -999); // Unrecognized offset
    expect(getIANATimezoneFromOffset()).toBe(undefined);
  });
});
