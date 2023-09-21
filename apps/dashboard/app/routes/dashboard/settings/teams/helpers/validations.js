import { required, minLength } from 'vuelidate/lib/validators';

export default {
  title: {
    required,
    minLength: minLength(2),
  },
  description: {},
  showOnSidebar: {},
};
