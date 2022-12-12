/* eslint no-script-url:0 */
/**
 * Check if a string contains mostly numbers
 */
function isMostlyNumbers(str = '') {
  return (
    str.length !== 0 && (str.match(/[0-9]/g) || '').length >= str.length / 2
  );
}

/**
 * Spit a string into an array with two pieces, at a given index
 * @param String	string to split
 * @param Number	index at which to split
 * @return Array
 */
function splitString(str, splitIndex) {
  return [str.substring(0, splitIndex), str.substring(splitIndex)];
}

function trimRight(str) {
  return str.replace(/\s+$/, '');
}

/**
 * Take a relative or absolute URL and pull it into it's indivisual pieces
 *
 * @param url (string)
 * @return urlPieces
 *	 .protocol	The protocol used, e.g. 'https://'
 *	 .domain		Domain name including sub domains and TLD, e.g. 'docs.deque.com'
 *	 .port			The port number, e.g. ':8080'
 *	 .path			Path after the domain, e.g. '/home.html'
 *	 .query		 Query string, e.g. '?user=admin&password=pass'
 *	 .hash			Hash / internal reference, e.g. '#footer'
 */
function uriParser(url) {
  const original = url;
  let protocol = '',
    domain = '',
    port = '',
    path = '',
    query = '',
    hash = '';
  if (url.includes('#')) {
    [url, hash] = splitString(url, url.indexOf('#'));
  }

  if (url.includes('?')) {
    [url, query] = splitString(url, url.indexOf('?'));
  }

  if (url.includes('://')) {
    [protocol, url] = url.split('://');
    [domain, url] = splitString(url, url.indexOf('/'));
  } else if (url.substr(0, 2) === '//') {
    url = url.substr(2);
    [domain, url] = splitString(url, url.indexOf('/'));
  }

  if (domain.substr(0, 4) === 'www.') {
    domain = domain.substr(4);
  }

  if (domain && domain.includes(':')) {
    [domain, port] = splitString(domain, domain.indexOf(':'));
  }

  path = url; // Whatever is left, must be the path
  return { original, protocol, domain, port, path, query, hash };
}

/**
 * Try to, at the end of the URI, find a string that a user can identify the URI by
 *
 * @param uri			 The URI to use
 * @param options
 *	 .currentDomain	The current domain name (optional)
 *	 .maxLength			Max length of the returned string (default: 25)
 * @return string	 A portion at the end of the uri, no longer than maxLength
 */
function getFriendlyUriEnd(uri = '', options = {}) {
  if (
    // Skip certain URIs:
    uri.length <= 1 || // very short
    uri.substr(0, 5) === 'data:' || // data URIs are unreadable
    uri.substr(0, 11) === 'javascript:' || // JS isn't a URL
    uri.includes('?') // query strings aren't very readable either
  ) {
    return;
  }

  const { currentDomain, maxLength = 25 } = options;
  const { path, domain, hash } = uriParser(uri);
  // Split the path at the last / that has text after it
  const pathEnd = path.substr(
    path.substr(0, path.length - 2).lastIndexOf('/') + 1
  );

  if (hash) {
    if (pathEnd && (pathEnd + hash).length <= maxLength) {
      return trimRight(pathEnd + hash);
    } else if (
      pathEnd.length < 2 &&
      hash.length > 2 &&
      hash.length <= maxLength
    ) {
      return trimRight(hash);
    } else {
      return;
    }
  } else if (domain && domain.length < maxLength && path.length <= 1) {
    // '' or '/'
    return trimRight(domain + path);
  }

  // See if the domain should be returned
  if (
    path === '/' + pathEnd &&
    domain &&
    currentDomain &&
    domain !== currentDomain &&
    (domain + path).length <= maxLength
  ) {
    return trimRight(domain + path);
  }

  const lastDotIndex = pathEnd.lastIndexOf('.');
  if (
    // Exclude very short or very long string
    (lastDotIndex === -1 || lastDotIndex > 1) &&
    (lastDotIndex !== -1 || pathEnd.length > 2) &&
    pathEnd.length <= maxLength &&
    // Exclude index files
    !pathEnd.match(/index(\.[a-zA-Z]{2-4})?/) &&
    // Exclude files that are likely to be database IDs
    !isMostlyNumbers(pathEnd)
  ) {
    return trimRight(pathEnd);
  }
}

export default getFriendlyUriEnd;
