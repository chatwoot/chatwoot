import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import OtherAttribute from '../OtherAttribute.vue';

const PLACEHOLDER = 'Enter value';

const i18n = createI18n({
  legacy: false,
  locale: 'en',
  messages: {
    en: {
      CONTACTS_LAYOUT: {
        SIDEBAR: {
          ATTRIBUTES: {
            TRIGGER: { INPUT: PLACEHOLDER },
            VALIDATIONS: {
              INVALID_URL: 'Invalid URL',
              INVALID_INPUT: 'Invalid input',
              INVALID_NUMBER: 'Invalid number',
              REQUIRED: 'This field is required',
            },
          },
        },
      },
    },
  },
});

const InputStub = {
  props: ['modelValue'],
  template: '<input :value="modelValue" />',
};

const mountAttribute = attribute =>
  mount(OtherAttribute, {
    props: { attribute },
    global: {
      plugins: [i18n],
      stubs: { Input: InputStub, Button: true },
      directives: { 'on-clickaway': {} },
    },
  });

describe('OtherAttribute', () => {
  it('displays 0 for a number attribute instead of the empty placeholder', () => {
    const wrapper = mountAttribute({
      attributeDisplayType: 'number',
      value: 0,
    });

    expect(wrapper.text()).toContain('0');
    expect(wrapper.text()).not.toContain(PLACEHOLDER);
  });

  it('displays the placeholder when the value is empty', () => {
    const wrapper = mountAttribute({
      attributeDisplayType: 'number',
      value: null,
    });

    expect(wrapper.text()).toContain(PLACEHOLDER);
  });

  it('does not show the placeholder when the value is false', () => {
    const wrapper = mountAttribute({
      attributeDisplayType: 'text',
      value: false,
    });

    expect(wrapper.text()).not.toContain(PLACEHOLDER);
  });

  it('keeps 0 in the editor when the value is opened for editing', async () => {
    const wrapper = mountAttribute({
      attributeDisplayType: 'number',
      value: 0,
    });

    await wrapper.find('span').trigger('click');

    expect(wrapper.find('input').element.value).toBe('0');
  });
});
