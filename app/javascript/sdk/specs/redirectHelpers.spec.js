import { parseRedirectParams, stripRedirectParams } from '../redirectHelpers';

describe('#parseRedirectParams', () => {
  it('returns null when the fragment carries no redirect token', () => {
    expect(parseRedirectParams('')).toBeNull();
    expect(parseRedirectParams('#')).toBeNull();
    expect(parseRedirectParams('#utm_source=x&foo=bar')).toBeNull();
  });

  it('parses the token and the open flag from the fragment', () => {
    expect(parseRedirectParams('#cw_redirect=abc123&cw_open=1')).toEqual({
      token: 'abc123',
      autoOpen: true,
    });
  });

  it('treats a missing cw_open as no auto-open', () => {
    expect(parseRedirectParams('#cw_redirect=abc123')).toEqual({
      token: 'abc123',
      autoOpen: false,
    });
  });
});

describe('#stripRedirectParams', () => {
  it('returns an empty string when only redirect params are present', () => {
    expect(stripRedirectParams('#cw_redirect=abc123&cw_open=1')).toBe('');
  });

  it('preserves other fragment params while removing the redirect ones', () => {
    expect(
      stripRedirectParams('#cw_redirect=abc123&cw_open=1&utm_source=x')
    ).toBe('#utm_source=x');
  });

  it('preserves a bare anchor segment untouched', () => {
    expect(stripRedirectParams('#pricing&cw_redirect=abc123&cw_open=1')).toBe(
      '#pricing'
    );
  });

  it('handles an empty fragment', () => {
    expect(stripRedirectParams('')).toBe('');
    expect(stripRedirectParams('#')).toBe('');
  });
});
