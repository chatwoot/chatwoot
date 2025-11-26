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

  const priorityMatches = [
    selectedLocale, // exact match
    lang, // base language match
    allowedLocales.find(l => l.startsWith(`${lang}_`)), // first variant match
  ];

  // Return the first match that exists in the allowed list, or null
  return priorityMatches.find(l => l && allowedLocales.includes(l)) ?? null;
};
