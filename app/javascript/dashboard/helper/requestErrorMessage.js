// Turns a failed API request into toast text from our own translations.
//
// The server's `message` is never shown: Rails' default validation messages are not translated
// for the languages we ship ("Email has already been taken" under pt_BR), so the text is built
// from the failing attribute and the error type that `render_record_invalid` sends in `details`.
// Only a request that never got an answer, or got a 5xx, keeps the flow's "try again later" text,
// since retrying can only help there.

const KNOWN_TYPES = ['taken', 'invalid', 'blank', 'too_long', 'too_short'];

export const CONTACT_FIELD_LABELS = {
  name: 'CONTACT_FORM.FORM.NAME.LABEL',
  email: 'CONTACT_FORM.FORM.EMAIL_ADDRESS.LABEL',
  phone_number: 'CONTACT_FORM.FORM.PHONE_NUMBER.LABEL',
  identifier: 'REQUEST_ERRORS.FIELDS.IDENTIFIER',
};

const isRetryable = response => !response || response.status >= 500;

const firstFailure = data => {
  const details = data?.details || {};
  const attribute = Object.keys(details)[0] || data?.attributes?.[0];
  return { attribute, type: details[attribute]?.[0]?.error };
};

/**
 * @param {Error} error a rejected request: an axios error, or a store exception carrying `response`
 * @param {Function} t vue-i18n translate
 * @param {string} fallbackKey the flow's own "could not save, try again later" key
 * @param {Object} fieldLabels attribute name -> i18n key of the field's label in this form
 * @returns {string}
 */
export const requestErrorMessage = (
  error,
  t,
  fallbackKey,
  fieldLabels = {}
) => {
  const response = error?.response;
  if (isRetryable(response) || response.status !== 422) return t(fallbackKey);

  const { attribute, type } = firstFailure(response.data);
  const kind = KNOWN_TYPES.includes(type) ? type.toUpperCase() : 'OTHER';
  const labelKey = fieldLabels[attribute];

  if (!labelKey) return t(`REQUEST_ERRORS.GENERIC.${kind}`);
  return t(`REQUEST_ERRORS.FIELD.${kind}`, { field: t(labelKey) });
};
