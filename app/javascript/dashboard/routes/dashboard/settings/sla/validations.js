import {
  required,
  minLength,
  numeric,
  minValue,
} from 'vuelidate/lib/validators';

export default {
  name: {
    required,
    minLength: minLength(2),
  },
  thresholdTime: {
    numeric,
    minValue: minValue(0.01),
  },
};
