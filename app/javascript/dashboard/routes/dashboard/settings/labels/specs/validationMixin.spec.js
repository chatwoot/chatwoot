import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueI18n from 'vue-i18n';
import validationMixin from '../validationMixin';

import i18n from 'dashboard/i18n';
const localVue = createLocalVue();
localVue.use(VueI18n);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

describe('validationMixin', () => {
  it('should return label required error message', () => {
    const Component = {
      render() {},
      title: 'TestComponent',
      mixins: [validationMixin],
      data() {
        return {
          title: '',
        };
      },
    };

    const wrapper = shallowMount(Component, { i18n: i18nConfig, localVue });
    expect(wrapper.vm.getLabelTitleErrorMessage).toBe('Label Name is required');
  });
});
