import parsePhoneNumber, { AsYouType } from 'libphonenumber-js';

/**
 * Formats a phone number into international human-readable format.
 * Returns the original string if parsing fails or input is invalid.
 *
 * Examples:
 *  '+905321234567' -> '+90 532 123 45 67'
 *  '+12025550123'  -> '+1 202 555 0123'
 *  '+442071838750' -> '+44 20 7183 8750'
 *
 * @param {string} phoneNumber - Raw phone number (usually E.164)
 * @returns {string} Formatted phone number or original input
 */
export const formatPhoneNumber = phoneNumber => {
  if (!phoneNumber || typeof phoneNumber !== 'string') {
    return '';
  }

  try {
    const parsed = parsePhoneNumber(phoneNumber);
    if (parsed) {
      return parsed.formatInternational();
    }
  } catch (error) {
    // If parsing throws (e.g. invalid phone number string), safely return original value
  }

  return phoneNumber;
};

/**
 * Formats an as-you-type input phone number for a given country and dial code.
 * Falls back to stripping international dial code for countries that require
 * a trunk prefix (leading 0) in national numbering plans (e.g. Afghanistan, UK, France).
 *
 * @param {string} dialCode - Country calling code (e.g. '+93', '+90')
 * @param {string} countryCode - ISO 3166-1 alpha-2 country code (e.g. 'AF', 'TR')
 * @param {string} value - Raw input value
 * @returns {string} Formatted input value
 */
export const formatAsYouTypeInput = (dialCode, countryCode, value) => {
  if (!value || typeof value !== 'string') {
    return '';
  }

  // Preserve raw input if it contains invalid non-phone characters (e.g. letters in '1-800-FLOWERS')
  // This ensures form validation rules can detect and reject malformed input rather than silently stripping characters.
  if (!/^[\d\s()+-]*$/.test(value)) {
    return value;
  }

  const digits = value.replace(/\D/g, '');
  if (!digits) {
    return '';
  }

  // 1. Try national formatting with country code
  const aytNat = new AsYouType(countryCode);
  const formattedNat = aytNat.input(digits);
  if (formattedNat !== digits) {
    return formattedNat;
  }

  // 2. Fallback: try international formatting with dial code and strip the dial code
  if (dialCode) {
    const aytInt = new AsYouType();
    const formattedInt = aytInt.input(`${dialCode}${digits}`);
    if (formattedInt.startsWith(dialCode)) {
      const stripped = formattedInt.slice(dialCode.length).trim();
      if (stripped) {
        return stripped;
      }
    }
  }

  return formattedNat;
};
