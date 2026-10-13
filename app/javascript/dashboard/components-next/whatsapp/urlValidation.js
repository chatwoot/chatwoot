const validHostname = hostname => {
  if (!hostname || hostname.length > 253) return false;
  if (hostname.startsWith('[') && hostname.endsWith(']')) return true;

  if (/^[\d.]+$/.test(hostname)) {
    const octets = hostname.split('.');
    return (
      octets.length === 4 &&
      octets.every(
        octet => /^(0|[1-9]\d{0,2})$/.test(octet) && Number(octet) <= 255
      )
    );
  }

  return hostname
    .split('.')
    .every(
      label =>
        label.length >= 1 &&
        label.length <= 63 &&
        /^[a-z\d](?:[a-z\d-]*[a-z\d])?$/i.test(label)
    );
};

export const isValidHttpUrl = (value, schemes = ['http', 'https']) => {
  const hasNonAscii = [...(value ?? '')].some(
    character => character.codePointAt(0) > 127
  );
  if (!value || /\s/.test(value) || hasNonAscii) return false;

  const match = value.match(/^[a-z][a-z\d+.-]*:\/\/([^/?#]+)/i);
  if (!match) return false;

  const authority = match[1].split('@').at(-1);
  const hostname = authority.startsWith('[')
    ? authority.slice(0, authority.indexOf(']') + 1)
    : authority.split(':')[0];

  try {
    const url = new URL(value);
    return (
      validHostname(hostname) &&
      url.port !== '0' &&
      schemes.includes(url.protocol.slice(0, -1))
    );
  } catch {
    return false;
  }
};
