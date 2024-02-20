import { required, minLength } from 'vuelidate/lib/validators';

export default {
  name: {
    required,
    minLength: minLength(2),
  },
  thresholdTime: {
    // if present, it must be a number and greater than 0
    // if not present, it's valid
    numeric: value => !value || !Number.isNaN(value),
  },
};
