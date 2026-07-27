import en from './locale/en.json';

// Additional locales are lazy-loaded on demand so the base bundle ships English only.
export const messages = { en };

export const loadLocale = async (composer, locale) => {
  if (composer.availableLocales.includes(locale)) return;

  try {
    const module = await import(`./locale/${locale}.json`);
    composer.setLocaleMessage(locale, module.default);
  } catch {
    // Locale file does not exist yet; stay on the fallback locale.
  }
};
