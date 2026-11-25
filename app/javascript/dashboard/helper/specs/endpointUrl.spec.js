import { endpointUrl } from '../endpointUrl';

describe('endpointUrl', () => {
  it('accepts the private and local addresses an install reaches its own services on', () => {
    [
      'http://10.40.10.20:3000/api/v1/chatwoot/webhook/tok',
      'http://192.168.0.5/hook',
      'http://agents:3000/api/v1/chatwoot/webhook/tok',
      'http://localhost:5678/webhook/abc',
      'https://bot.example.com/hook',
    ].forEach(value => {
      expect(endpointUrl(value)).toBe(true);
    });
  });

  it('rejects what is not an absolute http(s) URL', () => {
    [
      'bot.example.com/hook',
      'ftp://bot.example.com',
      // eslint-disable-next-line no-script-url
      'javascript:alert(1)',
      'http://',
      'not a url',
    ].forEach(value => {
      expect(endpointUrl(value)).toBe(false);
    });
  });

  it('rejects what the browser would repair but the server cannot parse', () => {
    [
      'http:/agents:3000/hook',
      'http:///hook',
      'https://example.com/hook ',
      ' https://example.com/hook',
      'http://exa mple.com/hook',
      'http:\\\\agents\\hook',
      'https://example.com/<hook>',
      'http://:3000/hook',
      'http://[zz]/hook',
    ].forEach(value => {
      expect(endpointUrl(value)).toBe(false);
    });
  });

  it('leaves an empty value to the required rule', () => {
    expect(endpointUrl('')).toBe(true);
  });
});
