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

const TestComponent = {
  render() {},
  mixins: [validationMixin],
  validations,
};

describe('validationMixin', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(TestComponent, {
      localVue,
      i18n: i18nConfig,
      data() {
        return {
          name: '',
        };
      },
    });
  });

  it('should not return required error message if name is empty but not touched', () => {
    wrapper.setData({ name: '' });
    expect(wrapper.vm.getSlaNameErrorMessage).toBe('');
  });

  it('should return empty error message if name is valid', () => {
    wrapper.setData({ name: 'ValidName' });
    wrapper.vm.$v.name.$touch();
    expect(wrapper.vm.getSlaNameErrorMessage).toBe('');
  });

  it('should return required error message if name is empty', () => {
    wrapper.setData({ name: '' });
    wrapper.vm.$v.name.$touch();
    expect(wrapper.vm.getSlaNameErrorMessage).toBe(
      wrapper.vm.$t('SLA.FORM.NAME.REQUIRED_ERROR')
    );
  });

  it('should return minimum length error message if name is too short', () => {
    wrapper.setData({ name: 'a' });
    wrapper.vm.$v.name.$touch();
    expect(wrapper.vm.getSlaNameErrorMessage).toBe(
      wrapper.vm.$t('SLA.FORM.NAME.MINIMUM_LENGTH_ERROR')
    );
  });
});
