import emailValidator from 'vuelidate/lib/validators/email';

export const validEmailsByComma = value => {
  if (!value.length) return true;
  const emails = value.replace(/\s+/g, '').split(',');
  return emails.every(email => emailValidator(email));
};
