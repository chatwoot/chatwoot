import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
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
  emits: ['click'],
  methods: {
    handleClick(event) {
      this.$emit('click', event);

      if (!this.$attrs.type || this.$attrs.type === 'submit') {
        this.$el.form?.dispatchEvent(
          new Event('submit', { bubbles: true, cancelable: true })
        );
      }
    },
  },
  template: `<button v-bind="$attrs" @click="handleClick">{{ label }}</button>`,
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

  it('does not submit parent forms when adding or removing email fields', async () => {
    const submitHandler = vi.fn(event => event.preventDefault());
    const wrapper = mount(
      {
        components: { ContactEmailsInput },
        data: () => ({
          emails: ['primary@example.com', 'alias@example.com'],
        }),
        methods: { submitHandler },
        template: `
          <form @submit="submitHandler">
            <ContactEmailsInput v-model="emails" />
          </form>
        `,
      },
      {
        global: {
          mocks: {
            $t: key => key,
          },
          stubs: {
            Input: InputStub,
            Button: ButtonStub,
          },
        },
      }
    );

    const buttons = wrapper.findAll('button');
    buttons[0].element.click();
    await nextTick();
    buttons[1].element.click();
    await nextTick();

    expect(submitHandler).not.toHaveBeenCalled();
  });
});
