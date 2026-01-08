import { getPhoneCodeByTimezone } from 'timezone-phone-codes';
import ct from 'countries-and-timezones';

const getTimezone = () => Intl.DateTimeFormat().resolvedOptions().timeZone;

// Default fallback to US
const DEFAULT_COUNTRY_CODE = 'US';
const DEFAULT_DIAL_CODE = '+1';

export const getActiveDialCode = () => {
  return getPhoneCodeByTimezone(getTimezone()) || DEFAULT_DIAL_CODE;
};

export const getActiveCountryCode = () => {
  const country = ct.getCountryForTimezone(getTimezone()) || {};
  return country.id || DEFAULT_COUNTRY_CODE;
};
