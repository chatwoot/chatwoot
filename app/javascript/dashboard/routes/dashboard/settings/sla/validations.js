import { required, minLength } from 'vuelidate/lib/validators';

export default {
  name: {
    required,
    minLength: minLength(2),
  },
};
