export const getBrowserLocale = enabledLanguages => {
  const localeWithVariant = window.navigator.language.replace('-', '_');
  const localeWithoutVariant = localeWithVariant.split('_')[0];
  return enabledLanguages.find(
    lang =>
      lang.iso_639_1_code === localeWithVariant ||
      lang.iso_639_1_code === localeWithoutVariant
  )?.iso_639_1_code;
};

export const getBrowserTimezone = () => {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
};
