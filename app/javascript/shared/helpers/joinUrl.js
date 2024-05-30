/**
 * Join multiple paths together with a base URL
 * NOTE: This function is not designed to handle query strings or fragments
 *
 * @param {string} baseUrl - The base URL to join the paths to
 * @param  {...string} paths - The paths to join
 * @returns {string} - The full URL
 */
export function joinUrl(baseUrl, ...paths) {
  // remove empty undefined and null path items
  // also handle if the path is just a slash or just multiple slashes only
  const sanitizedPaths = paths.filter(path => {
    if (!path) return false;
    if (path === null && path === '') return false;
    // if path is just a sequence of slashes
    if (/^\/+$/.test(path)) return false;

    return true;
  });

  const fullUrl = sanitizedPaths.reduce(
    (acc, path) => {
      const sanitizedPath = path.replace(/^\/+|\/+$/g, ''); // Remove leading and trailing slashes from each path segment
      return `${acc}/${sanitizedPath}`; // Concatenate with a single slash
    },
    baseUrl.replace(/\/+$/, '')
  );

  return fullUrl;
}
