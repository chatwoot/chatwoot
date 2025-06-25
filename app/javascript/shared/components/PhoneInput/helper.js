import { getPhoneCodeByTimezone } from 'timezone-phone-codes';
import ct from 'countries-and-timezones';

const getTimezone = () => Intl.DateTimeFormat().resolvedOptions().timeZone;

export const getActiveDialCode = () => {
  return getPhoneCodeByTimezone(getTimezone()) || '';
};

export const getActiveCountryCode = () => {
  const country = ct.getCountryForTimezone(getTimezone()) || {};
  return country.id || '';
};
