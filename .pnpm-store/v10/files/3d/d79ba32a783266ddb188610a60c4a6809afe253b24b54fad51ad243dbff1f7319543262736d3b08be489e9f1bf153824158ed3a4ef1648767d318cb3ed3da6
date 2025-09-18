/**
 * URL related helper functions
 */

/**
 * Converts various input formats to URL objects.
 * Handles URL objects, domain strings, relative paths, and full URLs.
 * @param {string|URL} input - Input to convert to URL object
 * @returns {URL|null} URL object or null if input is invalid
 */
export const toURL = (input: string | URL | null | undefined): URL | null => {
  if (!input) return null;
  if (input instanceof URL) return input;

  if (
    typeof input === 'string' &&
    !input.includes('://') &&
    !input.startsWith('/')
  ) {
    return new URL(`https://${input}`);
  }

  if (typeof input === 'string' && input.startsWith('/')) {
    return new URL(input, window.location.origin);
  }

  return new URL(input as string);
};

/**
 * Determines if two URLs belong to the same host by comparing their normalized URL objects.
 * Handles various input formats including URL objects, domain strings, relative paths, and full URLs.
 * Returns false if either URL cannot be parsed or normalized.
 * @param {string|URL} url1 - First URL to compare
 * @param {string|URL} url2 - Second URL to compare
 * @returns {boolean} True if both URLs have the same host, false otherwise
 */
export const isSameHost = (
  url1: string | URL | null | undefined,
  url2: string | URL | null | undefined
): boolean => {
  try {
    const urlObj1 = toURL(url1);
    const urlObj2 = toURL(url2);

    if (!urlObj1 || !urlObj2) return false;

    return urlObj1.hostname === urlObj2.hostname;
  } catch (error) {
    return false;
  }
};

/**
 * Check if a string is a valid domain name.
 * An empty string is allowed and considered valid.
 *
 * @param domain Domain to validate.
 * @returns Whether the domain matches the rules.
 */
export const isValidDomain = (domain: string): boolean => {
  if (domain === '') return true;

  const domainRegex = /^(?!-)(?!.*--)[\p{L}0-9-]{1,63}(?<!-)(?:\.(?!-)(?!.*--)[\p{L}0-9-]{1,63}(?<!-))*\.[\p{L}]{2,63}$/u;

  return domainRegex.test(domain) && domain.length <= 253;
};
