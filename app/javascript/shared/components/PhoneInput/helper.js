import { getPhoneCodeByTimezone } from 'timezone-phone-codes';
import ct from 'countries-and-timezones';

const getTimezone = () => Intl.DateTimeFormat().resolvedOptions().timeZone;

export const getActiveDialCode = () => {
  const code = getPhoneCodeByTimezone(getTimezone()) || '';
  if (code === '+52') return '+52 1';
  return code;
};

export const getActiveCountryCode = () => {
  const country = ct.getCountryForTimezone(getTimezone()) || {};
  const id = country.id || '';
  if (id === 'MX') return 'MX1';
  return id;
};
