import timeZoneData from 'dashboard/routes/dashboard/settings/inbox/helpers/timezones.json';

export const getBrowserLocale = enabledLanguages => {
  const [language, region] = navigator.language.split('-');
  const fullLocale = `${language}_${region || ''}`;
  return enabledLanguages.find(
    ({ iso_639_1_code }) =>
      iso_639_1_code === fullLocale || iso_639_1_code === language
  )?.iso_639_1_code;
};

export const getIANATimezoneFromOffset = () => {
  const offsetMinutes = new Date().getTimezoneOffset();
  const sign = offsetMinutes > 0 ? '-' : '+';
  const hours = Math.floor(Math.abs(offsetMinutes) / 60)
    .toString()
    .padStart(2, '0');
  const minutes = Math.abs(offsetMinutes % 60)
    .toString()
    .padStart(2, '0');
  const gmtOffset = `GMT${sign}${hours}:${minutes}`;

  const match =
    Object.keys(timeZoneData).find(key => key.includes(gmtOffset)) || 'UTC';
  // Loop through the keys and return the first one that matches the GMT offset
  return timeZoneData[match];
};
