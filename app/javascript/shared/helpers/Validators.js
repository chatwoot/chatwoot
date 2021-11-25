export const isPhoneE164 = value => !!value.match(/^\+[1-9]\d{1,14}$/);
export const isPhoneE164OrEmpty = value => isPhoneE164(value) || value === '';
export const shouldBeUrl = (value = '') =>
  value ? value.startsWith('http') : true;
