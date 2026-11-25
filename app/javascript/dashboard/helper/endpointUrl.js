// An admin-configured endpoint that Chatwoot's server calls (an agent bot or a webhook) or that the
// dashboard frames (a dashboard app) can live on a private network: a Docker service name such as
// `http://agents:3000`, or an address like `http://10.40.10.20:3000` that the server reaches through
// SAFE_FETCH_PRIVATE_TARGETS. Vuelidate's `url` rejects both (it requires a public TLD and excludes
// private ranges), so these forms accept any absolute http(s) URL instead.
//
// The form saves the string as typed, and the server parses it with Ruby's `URI.parse`, which takes
// only RFC 3986 characters and needs a literal `scheme://host`. The browser's `new URL` repairs what
// Ruby rejects (`http:/agents:3000`, `http:///x`, trailing spaces), so the syntax is checked on the
// original string and `new URL` only confirms the host is valid. An empty value passes here, and
// `required` is what rejects it.
const AUTHORITY = "[A-Za-z0-9\\-._~!$&'()*+,;=%@:\\[\\]]+";
const REST = "(?:[/?#][A-Za-z0-9\\-._~:/?#\\[\\]@!$&'()*+,;=%]*)?";
const ENDPOINT_URL = new RegExp(`^https?://${AUTHORITY}${REST}$`, 'i');

export const endpointUrl = value => {
  if (!value) return true;
  if (!ENDPOINT_URL.test(value)) return false;
  try {
    return !!new URL(value).hostname;
  } catch {
    return false;
  }
};
