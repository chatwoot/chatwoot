import { required, minLength } from '@vuelidate/validators';

export default {
  title: {
    required,
    minLength: minLength(2),
  },
  description: {},
  showOnSidebar: {},
};
