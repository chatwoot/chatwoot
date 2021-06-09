import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueI18n from 'vue-i18n';
import Vuelidate from 'vuelidate';

import validationMixin from '../validationMixin';
import validations from '../validations';
import i18n from 'dashboard/i18n';
const localVue = createLocalVue();

localVue.use(VueI18n);
localVue.use(Vuelidate);
const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});
const Component = {
  render() {},
  title: 'TestComponent',
  mixins: [validationMixin],
  validations,
};

describe('validationMixin', () => {
  it('it should return empty error message if valid label name passed', async () => {
    const wrapper = shallowMount(Component, {
      i18n: i18nConfig,
      localVue,
      data() {
        return {
          title: 'sales',
        };
      },
    });
    expect(wrapper.vm.getLabelTitleErrorMessage).toBe('');
  });
  it('it should return label required error message if empty name is passed', async () => {
    const wrapper = shallowMount(Component, {
      i18n: i18nConfig,
      localVue,
      data() {
        return {
          title: '',
        };
      },
    });
    expect(wrapper.vm.getLabelTitleErrorMessage).toBe('Label name is required');
  });
  it('it should return label minimum length error message if one charceter label name is passed', async () => {
    const wrapper = shallowMount(Component, {
      i18n: i18nConfig,
      localVue,
      data() {
        return {
          title: 's',
        };
      },
    });
    expect(wrapper.vm.getLabelTitleErrorMessage).toBe(
      'Minimum length 2 is required'
    );
  });
  it('it should return invalid character error message if invalid lable name passed', async () => {
    const wrapper = shallowMount(Component, {
      i18n: i18nConfig,
      localVue,
      data() {
        return {
          title: 'sales enquiry',
        };
      },
    });
    expect(wrapper.vm.getLabelTitleErrorMessage).toBe(
      'Only Alphabets, Numbers, Hyphen and Underscore are allowed'
    );
  });
});
