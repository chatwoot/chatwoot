import { required } from 'vuelidate/lib/validators';

export default {
  title: {
    required,
    // allowing user to name their chatbot any character also
    // minLength: minLength(2),
  },
  description: {},
  showOnSidebar: {},
};
