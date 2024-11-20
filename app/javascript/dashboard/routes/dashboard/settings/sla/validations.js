import { required, minLength, minValue, decimal } from '@vuelidate/validators';

export default {
  name: {
    required,
    minLength: minLength(2),
  },
  thresholdTime: {
    decimal,
    minValue: minValue(0.001),
  },
};
