const FLAG_OFFSET = 127397;

/**
 * Gets emoji flag for given locale.
 *
 * @param {string} countryCode locale code
 * @return {string} emoji flag
 *
 * @example
 * getCountryFlag('cz') // '🇨🇿'
 */
export const getCountryFlag = countryCode => {
  const codePoints = countryCode
    .toUpperCase()
    .split('')
    .map(char => FLAG_OFFSET + char.charCodeAt());

  return String.fromCodePoint(...codePoints);
};
