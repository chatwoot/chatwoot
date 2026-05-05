import { defineComponent, h } from 'vue';
import { mount } from '@vue/test-utils';
import ContactPointListInput from '../ContactPointListInput.vue';

const InputStub = defineComponent({
  name: 'ContactPointTextInputStub',
  props: {
    modelValue: {
      type: String,
      default: '',
    },
  },
  emits: ['update:modelValue'],
  setup(props, { attrs, emit }) {
    return () =>
      h('input', {
        ...attrs,
        value: props.modelValue,
        onInput: event => emit('update:modelValue', event.target.value),
      });
  },
});

const PhoneNumberInputStub = defineComponent({
  name: 'PhoneNumberInput',
  props: {
    modelValue: {
      type: String,
      default: '',
    },
  },
  emits: ['update:modelValue'],
  setup(props, { attrs, emit }) {
    return () =>
      h('input', {
        ...attrs,
        value: props.modelValue,
        onInput: event => emit('update:modelValue', event.target.value),
      });
  },
});

const buildWrapper = (props = {}) =>
  mount(ContactPointListInput, {
    props: {
      modelValue: ['alias@example.com'],
      type: 'email',
      primaryValue: 'primary@example.com',
      label: 'Additional emails',
      addLabel: 'Add email',
      promoteLabel: 'Set as primary',
      removeLabel: 'Remove',
      ...props,
    },
    global: {
      stubs: {
        Input: InputStub,
        PhoneNumberInput: PhoneNumberInputStub,
      },
    },
  });

describe('ContactPointListInput', () => {
  it('renders email rows with Input and emits additional email updates', async () => {
    const wrapper = buildWrapper();

    expect(wrapper.findComponent(InputStub).exists()).toBe(true);
    expect(wrapper.findComponent(PhoneNumberInputStub).exists()).toBe(false);

    wrapper
      .findComponent(InputStub)
      .vm.$emit('update:modelValue', 'billing@example.com');

    expect(wrapper.emitted('update:modelValue').at(-1)[0]).toEqual([
      'billing@example.com',
    ]);
  });

  it('renders phone rows with PhoneNumberInput and emits promote/remove actions', async () => {
    const wrapper = buildWrapper({
      modelValue: ['+14155550124'],
      type: 'phone',
      primaryValue: '+14155550123',
      label: 'Additional phones',
      addLabel: 'Add phone',
    });

    expect(wrapper.findComponent(PhoneNumberInputStub).exists()).toBe(true);
    expect(wrapper.findComponent(InputStub).exists()).toBe(false);

    await wrapper.find('[data-testid="contact-point-add"]').trigger('click');
    expect(wrapper.emitted('update:modelValue').at(-1)[0]).toEqual([
      '+14155550124',
      '',
    ]);

    await wrapper
      .find('[data-testid="contact-point-promote"]')
      .trigger('click');
    expect(wrapper.emitted('promote').at(-1)[0]).toBe('+14155550124');

    await wrapper.find('[data-testid="contact-point-remove"]').trigger('click');
    expect(wrapper.emitted('update:modelValue').at(-1)[0]).toEqual([]);
  });
});
