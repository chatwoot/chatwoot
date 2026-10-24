import { parsePhoneNumber, isValidPhoneNumber } from 'libphonenumber-js';
import { email } from '@vuelidate/validators';

export const MODE = {
  SINGLE: 'single',
  MULTIPLE: 'multiple',
};

export const INPUT_TYPES = {
  EMAIL: 'email',
  TEL: 'tel',
  TEXT: 'text',
};

export const validatePhoneNumber = value => {
  if (!value) return true;
  try {
    return isValidPhoneNumber(value);
  } catch (error) {
    return false;
  }
};

export const formatPhoneNumber = value => {
  try {
    const phoneNumber = parsePhoneNumber(value);
    return {
      isValid: phoneNumber?.isValid() || false,
      formattedValue: phoneNumber?.formatInternational() || value,
    };
  } catch (error) {
    return { isValid: false, formattedValue: value };
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

const digitsOnly = value => String(value ?? '').replace(/\D/g, '');

// Match the typed value against the listed items by email OR phone number, so
// pressing Enter on a phone number selects the existing contact instead of
// trying to create it again (which fails: "Phone number has already been taken").
export const findMatchingMenuItem = (menuItems, value) => {
  const trimmed = String(value ?? '').trim();
  if (!trimmed) return undefined;
  const byEmail = menuItems.find(
    item => item.email && item.email.toLowerCase() === trimmed.toLowerCase()
  );
  if (byEmail) return byEmail;
  const digits = digitsOnly(trimmed);
  if (digits.length < 7) return undefined;
  return menuItems.find(
    item => item.phoneNumber && digitsOnly(item.phoneNumber) === digits
  );
};
