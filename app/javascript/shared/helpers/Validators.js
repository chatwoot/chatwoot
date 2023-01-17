export const isPhoneE164 = value => !!value.match(/^\+[1-9]\d{1,14}$/);
export const isPhoneE164OrEmpty = value => isPhoneE164(value) || value === '';
export const shouldBeUrl = (value = '') =>
  value ? value.startsWith('http') : true;
export const isValidPassword = value => {
  const containsUppercase = /[A-Z]/.test(value);
  const containsLowercase = /[a-z]/.test(value);
  const containsNumber = /[0-9]/.test(value);
  const containsSpecialCharacter = /[!@#$%^&*()_+\-=[\]{}|'"/\\.,`<>:;?~]/.test(
    value
  );
  return (
    containsUppercase &&
    containsLowercase &&
    containsNumber &&
    containsSpecialCharacter
  );
};
export const isNumber = value => /^\d+$/.test(value);
export const isDomain = value => {
  if (value !== '') {
    const domainRegex = /^([\p{L}0-9]+(-[\p{L}0-9]+)*\.)+[a-z]{2,}$/gmu;
    return domainRegex.test(value);
  }
  return true;
};
