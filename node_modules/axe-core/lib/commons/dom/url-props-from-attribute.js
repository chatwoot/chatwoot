/**
 * Parse resource object for a given node from a specified attribute
 * @method urlPropsFromAttribute
 * @param {HTMLElement} node given node
 * @param {String} attribute attribute of the node from which resource should be parsed
 * @returns {Object}
 */
function urlPropsFromAttribute(node, attribute) {
  if (!node.hasAttribute(attribute)) {
    return undefined;
  }

  const nodeName = node.nodeName.toUpperCase();
  let parser = node;

  /**
   * Note:
   * The need to create a parser, is to keep this function generic, to be able to parse resource from element(s) like `iframe` with `src` attribute,
   *
   * Also, when `a` or `area` is nested inside an svg document,
   * they do not have url properties as a HTML Node, hence the check for `ownerSVGElement`
   */
  if (!['A', 'AREA'].includes(nodeName) || node.ownerSVGElement) {
    parser = document.createElement('a');
    parser.href = node.getAttribute(attribute);
  }

  /**
   * Curate `https` and `ftps` to `http` and `ftp` as they will resolve to same resource
   */
  const protocol = [`https:`, `ftps:`].includes(parser.protocol)
    ? parser.protocol.replace(/s:$/, ':')
    : parser.protocol;

  /**
   * certain browser (in this case IE10 & 11)
   * does not resolve pathname with a beginning slash, thence prepending with a beginning slash
   */
  const parserPathname = /^\//.test(parser.pathname)
    ? parser.pathname
    : `/${parser.pathname}`;
  const { pathname, filename } = getPathnameOrFilename(parserPathname);

  return {
    protocol,
    hostname: parser.hostname,
    port: getPort(parser.port),
    pathname: /\/$/.test(pathname) ? pathname : `${pathname}/`,
    search: getSearchPairs(parser.search),
    hash: getHashRoute(parser.hash),
    filename
  };
}

/**
 * Resolve given port excluding default port(s)
 * @param {String} port port
 * @returns {String}
 */
function getPort(port) {
  const excludePorts = [
    `443`, // default `https` port
    `80`
  ];
  return !excludePorts.includes(port) ? port : ``;
}

/**
 * Resolve if a given pathname has filename & resolve the same as parts
 * @method getPathnameOrFilename
 * @param {String} pathname pathname part of a given uri
 * @returns {Array<Object>}
 */
function getPathnameOrFilename(pathname) {
  const filename = pathname.split('/').pop();
  if (!filename || filename.indexOf('.') === -1) {
    return {
      pathname,
      filename: ``
    };
  }

  return {
    // remove `filename` from `pathname`
    pathname: pathname.replace(filename, ''),

    // ignore filename when index.*
    filename: /index./.test(filename) ? `` : filename
  };
}

/**
 * Parse a given query string to key/value pairs sorted alphabetically
 * @param {String} searchStr search string
 * @returns {Object}
 */
function getSearchPairs(searchStr) {
  const query = {};

  if (!searchStr || !searchStr.length) {
    return query;
  }

  // `substring` to remove `?` at the beginning of search string
  const pairs = searchStr.substring(1).split(`&`);
  if (!pairs || !pairs.length) {
    return query;
  }

  for (let index = 0; index < pairs.length; index++) {
    const pair = pairs[index];
    const [key, value = ''] = pair.split(`=`);
    query[decodeURIComponent(key)] = decodeURIComponent(value);
  }

  return query;
}

/**
 * Interpret a given hash
 * if `hash`
 * -> is `hashbang` -or- `hash` is followed by `slash`
 * -> it resolves to a different resource
 * @method getHashRoute
 * @param {String} hash hash component of a parsed uri
 * @returns {String}
 */
function getHashRoute(hash) {
  if (!hash) {
    return ``;
  }

  /**
   * Check for any conventionally-formatted hashbang that may be present
   * eg: `#, #/, #!, #!/`
   */
  const hashRegex = /#!?\/?/g;
  const hasMatch = hash.match(hashRegex);
  if (!hasMatch) {
    return ``;
  }

  // do not resolve inline link as hash
  const [matchedStr] = hasMatch;
  if (matchedStr === '#') {
    return ``;
  }

  return hash;
}

export default urlPropsFromAttribute;
