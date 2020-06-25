import { required, minLength } from 'vuelidate/lib/validators';

export const validLabelCharacters = (str = '') => /^[\w-_]+$/g.test(str);

export default {
  title: {
    required,
    minLength: minLength(2),
    validLabelCharacters,
  },
  description: {},
  color: {
    required,
  },
  showOnSidebar: {},
};
