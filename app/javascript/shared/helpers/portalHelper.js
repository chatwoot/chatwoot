/**
 * Determine the best-matching locale from the list of locales allowed by the portal.
 *
 * The matching happens in the following order:
 * 1. Exact match – the visitor-selected locale equals one in the `allowedLocales` list
 *    (e.g., `fr` ➜ `fr`).
 * 2. Base language match – the base part of a compound locale (before the underscore)
 *    matches (e.g., `fr_CA` ➜ `fr`).
 * 3. Variant match – when the base language is selected but a regional variant exists
 *    in the portal list (e.g., `fr` ➜ `fr_BE`).
 *
 * If none of these rules find a match, the function returns `null`,
 * Don't show popular articles if locale doesn't match with allowed locales
 *
 * @export
 * @param {string} selectedLocale The locale selected by the visitor (e.g., `fr_CA`).
 * @param {string[]} allowedLocales Array of locales enabled for the portal.
 * @returns {(string|null)} A locale string that should be used, or `null` if no suitable match.
 */
export const getMatchingLocale = (selectedLocale = '', allowedLocales = []) => {
  // Ensure inputs are valid
  if (
    !selectedLocale ||
    !Array.isArray(allowedLocales) ||
    !allowedLocales.length
  ) {
    return null;
  }

  const [lang] = selectedLocale.split('_');

  // Priority 1: Exact match
  if (allowedLocales.includes(selectedLocale)) {
    return selectedLocale;
  }

  // Priority 2: Base language match
  if (allowedLocales.includes(lang)) {
    return lang;
  }

  // Priority 3: Variant match
  const variantMatch = allowedLocales.find(l => l.startsWith(`${lang}_`));
  if (variantMatch) {
    return variantMatch;
  }

  // No match found
  return null;
};
