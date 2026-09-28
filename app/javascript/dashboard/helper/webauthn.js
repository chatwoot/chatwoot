// Bridges the server's JSON WebAuthn options to navigator.credentials and back.
// Native parseCreationOptionsFromJSON is not in every browser we support yet.

export const base64UrlToBuffer = value => {
  const base64 = value.replace(/-/g, '+').replace(/_/g, '/');
  const padded = base64.padEnd(Math.ceil(base64.length / 4) * 4, '=');
  const binary = window.atob(padded);
  return Uint8Array.from(binary, char => char.charCodeAt(0)).buffer;
};

export const bufferToBase64Url = buffer => {
  const binary = String.fromCharCode(...new Uint8Array(buffer));
  return window
    .btoa(binary)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
};

export const isPasskeySupported = () =>
  typeof window !== 'undefined' &&
  window.isSecureContext &&
  typeof window.PublicKeyCredential === 'function' &&
  typeof navigator.credentials?.get === 'function';

const withBufferIds = (credentials = []) =>
  credentials.map(credential => ({
    ...credential,
    id: base64UrlToBuffer(credential.id),
  }));

export const toCreationOptions = options => ({
  ...options,
  challenge: base64UrlToBuffer(options.challenge),
  user: { ...options.user, id: base64UrlToBuffer(options.user.id) },
  excludeCredentials: withBufferIds(options.excludeCredentials),
});

export const toRequestOptions = options => ({
  ...options,
  challenge: base64UrlToBuffer(options.challenge),
  allowCredentials: withBufferIds(options.allowCredentials),
});

export const credentialToJSON = credential => {
  const { response } = credential;
  const json = {
    id: credential.id,
    rawId: bufferToBase64Url(credential.rawId),
    type: credential.type,
    authenticatorAttachment: credential.authenticatorAttachment,
    response: {
      clientDataJSON: bufferToBase64Url(response.clientDataJSON),
    },
  };
  if (response.attestationObject) {
    json.response.attestationObject = bufferToBase64Url(
      response.attestationObject
    );
    json.response.transports = response.getTransports?.() || [];
  }
  if (response.authenticatorData) {
    json.response.authenticatorData = bufferToBase64Url(
      response.authenticatorData
    );
    json.response.signature = bufferToBase64Url(response.signature);
    json.response.userHandle = response.userHandle
      ? bufferToBase64Url(response.userHandle)
      : null;
  }
  return json;
};

export const createPasskey = async options => {
  const credential = await navigator.credentials.create({
    publicKey: toCreationOptions(options),
  });
  return credentialToJSON(credential);
};

export const getPasskey = async options => {
  const credential = await navigator.credentials.get({
    publicKey: toRequestOptions(options),
  });
  return credentialToJSON(credential);
};

// The user dismissing the browser prompt is not an error worth reporting.
export const isPasskeyPromptDismissed = error =>
  error?.name === 'NotAllowedError' || error?.name === 'AbortError';
