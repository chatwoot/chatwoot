export const getBrowserLocale = enabledLanguages => {
  const [language, region] = navigator.language.split('-');
  const fullLocale = `${language}_${region || ''}`;
  return enabledLanguages.find(
    ({ iso_639_1_code }) =>
      iso_639_1_code === fullLocale || iso_639_1_code === language
  )?.iso_639_1_code;
};

export const getBrowserTimezone = () => {
  return Intl.DateTimeFormat().resolvedOptions().timeZone;
};
