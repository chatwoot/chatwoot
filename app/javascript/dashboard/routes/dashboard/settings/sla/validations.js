import { required, minLength } from 'vuelidate/lib/validators';

const isValidSlaFormat = value => {
  if (!value) return true;
  const stringValue = String(value);
  const regex = /^\d+(.\d+)?$/;
  return regex.test(stringValue) && parseFloat(value) > 0;
};

export default {
  name: {
    required,
    minLength: minLength(2),
  },
  thresholdTime: {
    isValidSlaFormat,
  },
};
