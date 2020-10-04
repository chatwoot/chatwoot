import { required, minLength } from 'vuelidate/lib/validators';

export const validLabelCharacters = (str = '') => !/ /.test(str);
export const notEmptyInput = (str = '') => !!str;

export default {
  title: {
    required,
    minLength: minLength(2),
    validLabelCharacters,
    notEmptyInput,
  },
  description: {},
  color: {
    required,
  },
  showOnSidebar: {},
};
