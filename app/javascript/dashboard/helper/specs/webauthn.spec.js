import {
  base64UrlToBuffer,
  bufferToBase64Url,
  credentialToJSON,
  isPasskeyPromptDismissed,
  toCreationOptions,
  toRequestOptions,
} from '../webauthn';

const bytes = values => Uint8Array.from(values).buffer;

describe('webauthn helper', () => {
  describe('base64url round trip', () => {
    it('encodes without padding or url-unsafe characters', () => {
      expect(bufferToBase64Url(bytes([251, 255, 191]))).toBe('-_-_');
      expect(bufferToBase64Url(bytes([1]))).toBe('AQ');
    });

    it('decodes what it encodes', () => {
      const original = bytes([0, 1, 2, 250, 251, 252, 253, 254, 255]);
      const decoded = base64UrlToBuffer(bufferToBase64Url(original));

      expect(new Uint8Array(decoded)).toEqual(new Uint8Array(original));
    });
  });

  it('turns creation option ids into buffers', () => {
    const options = toCreationOptions({
      challenge: 'AQID',
      rp: { id: 'app.example.com', name: 'Chatwoot' },
      user: { id: 'BAUG', name: 'agent@example.com' },
      excludeCredentials: [{ type: 'public-key', id: 'Bwg' }],
    });

    expect(new Uint8Array(options.challenge)).toEqual(
      new Uint8Array([1, 2, 3])
    );
    expect(new Uint8Array(options.user.id)).toEqual(new Uint8Array([4, 5, 6]));
    expect(options.user.name).toBe('agent@example.com');
    expect(new Uint8Array(options.excludeCredentials[0].id)).toEqual(
      new Uint8Array([7, 8])
    );
  });

  it('tolerates request options without allowCredentials', () => {
    const options = toRequestOptions({
      challenge: 'AQID',
      userVerification: 'required',
    });

    expect(options.allowCredentials).toEqual([]);
    expect(options.userVerification).toBe('required');
  });

  it('serialises an assertion for the server', () => {
    const json = credentialToJSON({
      id: 'Bwg',
      rawId: bytes([7, 8]),
      type: 'public-key',
      authenticatorAttachment: 'platform',
      response: {
        clientDataJSON: bytes([1]),
        authenticatorData: bytes([2]),
        signature: bytes([3]),
        userHandle: bytes([4]),
      },
    });

    expect(json).toEqual({
      id: 'Bwg',
      rawId: 'Bwg',
      type: 'public-key',
      authenticatorAttachment: 'platform',
      response: {
        clientDataJSON: 'AQ',
        authenticatorData: 'Ag',
        signature: 'Aw',
        userHandle: 'BA',
      },
    });
  });

  it('serialises an attestation with its transports', () => {
    const json = credentialToJSON({
      id: 'Bwg',
      rawId: bytes([7, 8]),
      type: 'public-key',
      response: {
        clientDataJSON: bytes([1]),
        attestationObject: bytes([5]),
        getTransports: () => ['internal', 'hybrid'],
      },
    });

    expect(json.response).toEqual({
      clientDataJSON: 'AQ',
      attestationObject: 'BQ',
      transports: ['internal', 'hybrid'],
    });
  });

  it('treats a dismissed browser prompt as a non-error', () => {
    expect(isPasskeyPromptDismissed({ name: 'NotAllowedError' })).toBe(true);
    expect(isPasskeyPromptDismissed({ name: 'AbortError' })).toBe(true);
    expect(isPasskeyPromptDismissed(new Error('boom'))).toBe(false);
  });
});
