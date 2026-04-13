import { mount } from '@vue/test-utils';
import ContactEmailsInput from '../ContactEmailsInput.vue';

const InputStub = {
  name: 'Input',
  props: [
    'modelValue',
    'placeholder',
    'message',
    'messageType',
    'customInputClass',
    'type',
  ],
  template: `
    <input
      :value="modelValue"
      :placeholder="placeholder"
      @input="$emit('update:modelValue', $event.target.value)"
      @blur="$emit('blur')"
    />
  `,
};

const ButtonStub = {
  name: 'Button',
  props: ['label', 'icon'],
  template: `<button type="button" @click="$emit('click')">{{ label }}</button>`,
};

describe('ContactEmailsInput', () => {
  it('reflows remaining alias into the primary slot when the model collapses', async () => {
    const wrapper = mount(ContactEmailsInput, {
      props: {
        modelValue: ['primary@example.com', 'alias@example.com'],
        primaryPlaceholder: 'Primary email',
        additionalPlaceholder: 'Additional email',
      },
      global: {
        mocks: {
          $t: key => key,
        },
        stubs: {
          Input: InputStub,
          Button: ButtonStub,
        },
      },
    });

    const inputs = wrapper.findAll('input');
    await inputs[0].setValue('');

    await wrapper.setProps({
      modelValue: ['alias@example.com'],
    });

    const updatedInputs = wrapper.findAll('input');
    expect(updatedInputs).toHaveLength(1);
    expect(updatedInputs[0].element.value).toBe('alias@example.com');
    expect(updatedInputs[0].attributes('placeholder')).toBe('Primary email');
  });
});
