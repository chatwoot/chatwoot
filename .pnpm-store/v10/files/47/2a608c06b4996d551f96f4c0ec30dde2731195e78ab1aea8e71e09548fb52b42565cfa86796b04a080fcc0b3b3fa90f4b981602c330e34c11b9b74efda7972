Object.defineProperty(exports, '__esModule', { value: true });

/**
 * Checks whether given url points to Sentry server
 *
 * @param url url to verify
 */
function isSentryRequestUrl(url, client) {
  const dsn = client && client.getDsn();
  const tunnel = client && client.getOptions().tunnel;
  return checkDsn(url, dsn) || checkTunnel(url, tunnel);
}

function checkTunnel(url, tunnel) {
  if (!tunnel) {
    return false;
  }

  return removeTrailingSlash(url) === removeTrailingSlash(tunnel);
}

function checkDsn(url, dsn) {
  return dsn ? url.includes(dsn.host) : false;
}

function removeTrailingSlash(str) {
  return str[str.length - 1] === '/' ? str.slice(0, -1) : str;
}

exports.isSentryRequestUrl = isSentryRequestUrl;
//# sourceMappingURL=isSentryRequestUrl.js.map
