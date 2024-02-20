import { required, minLength, numeric } from 'vuelidate/lib/validators';

const notZero = value => value !== 0;

export default {
  name: {
    required,
    minLength: minLength(2),
  },
  // if present, it must be a number and greater than 0
  // if not present, it's valid
  thresholdTime: {
    numeric,
    notZero,
  },
};
