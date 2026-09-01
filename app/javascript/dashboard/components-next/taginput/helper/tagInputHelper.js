import { parsePhoneNumber, isValidPhoneNumber } from 'libphonenumber-js';
import { email } from '@vuelidate/validators';
import { getActiveCountryCode } from 'shared/components/PhoneInput/helper';

export const MODE = {
  SINGLE: 'single',
  MULTIPLE: 'multiple',
};

export const INPUT_TYPES = {
  EMAIL: 'email',
  TEL: 'tel',
  TEXT: 'text',
};

// Digits with optional leading + and common separators — at least one digit.
const PHONE_LIKE_REGEX = /^\+?[\d\s().-]*\d[\d\s().-]*$/;

export const isPhoneLikeInput = value =>
  PHONE_LIKE_REGEX.test(value?.trim() || '');

export const detectInputType = value =>
  isPhoneLikeInput(value) ? INPUT_TYPES.TEL : INPUT_TYPES.EMAIL;

const defaultCountry = () => getActiveCountryCode() || undefined;

export const validatePhoneNumber = value => {
  if (!value) return true;
  try {
    return isValidPhoneNumber(value, defaultCountry());
  } catch (error) {
    return false;
  }
};

export const formatPhoneNumber = value => {
  try {
    const phoneNumber = parsePhoneNumber(value, defaultCountry());
    return {
      isValid: phoneNumber?.isValid() || false,
      formattedValue: phoneNumber?.formatInternational() || value,
    };
  } catch (error) {
    return { isValid: false, formattedValue: value };
  }
};

export const normalizePhoneNumber = value => {
  if (!value) return null;
  try {
    const phoneNumber = parsePhoneNumber(value, defaultCountry());
    return phoneNumber?.isValid() ? phoneNumber.number : null;
  } catch (error) {
    return null;
  }
};

export const getValidationRules = type => ({
  newTag: {
    ...(type === INPUT_TYPES.EMAIL ? { email } : {}),
    ...(type === INPUT_TYPES.TEL ? { isValidPhone: validatePhoneNumber } : {}),
  },
});

export const checkTagTypeValidity = (type, value, v$) => {
  if (type === INPUT_TYPES.TEL) {
    return !validatePhoneNumber(value);
  }
  return v$.$invalid;
};

export const validateAndFormatNewTag = (
  trimmedNewTag,
  type,
  isNewTagInValidType
) => {
  let isValid = true;
  let formattedValue = trimmedNewTag;

  if (type === INPUT_TYPES.EMAIL) {
    isValid = !isNewTagInValidType;
  } else if (type === INPUT_TYPES.TEL) {
    const { isValid: phoneValid, formattedValue: phoneFormatted } =
      formatPhoneNumber(trimmedNewTag);
    isValid = phoneValid;
    formattedValue = phoneFormatted;
  }

  return { isValid, formattedValue };
};

export const createNewTagMenuItem = (formattedValue, trimmedNewTag, type) => ({
  label: formattedValue,
  value: trimmedNewTag,
  ...(type === INPUT_TYPES.EMAIL ? { email: trimmedNewTag } : {}),
  ...(type === INPUT_TYPES.TEL ? { phoneNumber: trimmedNewTag } : {}),
  thumbnail: { name: formattedValue, src: '' },
  action: 'create',
});

export const buildTagMenuItems = ({
  mode,
  tags,
  menuItems,
  newTag,
  isLoading,
  type,
  isNewTagInValidType,
  allowCreate = true,
  skipLabelDedup = false,
}) => {
  if (mode === MODE.SINGLE && tags.length >= 1) return [];

  const availableMenuItems = skipLabelDedup
    ? menuItems
    : menuItems.filter(item => !tags.includes(item.label));

  // Show typed value as suggestion only if:
  // 1. There's a value being typed
  // 2. The value isn't already in the tags
  // 3. Validation passes (email/phone) and There are no menu items available
  // 4. allowCreate is enabled
  const trimmedNewTag = newTag?.trim();
  const shouldShowCreateSuggestion =
    allowCreate &&
    trimmedNewTag &&
    !tags.includes(trimmedNewTag) &&
    !isLoading &&
    !availableMenuItems.length;

  if (shouldShowCreateSuggestion) {
    const { isValid, formattedValue } = validateAndFormatNewTag(
      trimmedNewTag,
      type,
      isNewTagInValidType
    );

    if (isValid) {
      return [createNewTagMenuItem(formattedValue, trimmedNewTag, type)];
    }
  }

  return availableMenuItems;
};

export const canAddTag = (mode, tagsLength) =>
  !(mode === MODE.SINGLE && tagsLength >= 1);

export const findMatchingMenuItem = (
  menuItems,
  value,
  type = INPUT_TYPES.EMAIL
) => {
  if (type === INPUT_TYPES.TEL) {
    const normalized = normalizePhoneNumber(value);
    if (!normalized) return undefined;
    return menuItems.find(
      item =>
        item.phoneNumber &&
        normalizePhoneNumber(item.phoneNumber) === normalized
    );
  }
  return menuItems.find(item => item.email === value);
};

// A tel search can match an email-only contact (numeric name/identifier);
// select it as email and skip the mismatched phone validation.
export const resolveDropdownSelection = (
  type,
  { email: emailAddress, phoneNumber, label }
) => {
  const isEmailOnlyItem = !phoneNumber && !!emailAddress;
  const isEmail =
    type === INPUT_TYPES.EMAIL || (type === INPUT_TYPES.TEL && isEmailOnlyItem);
  return {
    isEmail,
    tagValue: isEmail ? emailAddress : phoneNumber || label,
    shouldValidate:
      type === INPUT_TYPES.EMAIL ||
      (type === INPUT_TYPES.TEL && !isEmailOnlyItem),
  };
};
