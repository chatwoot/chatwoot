import { required, minLength } from 'vuelidate/lib/validators';

const isValidSlaFormat = value => {
  if (value === '') return true;
  const numValue = Number(value);
  return Number.isFinite(numValue) && numValue > 0;
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
