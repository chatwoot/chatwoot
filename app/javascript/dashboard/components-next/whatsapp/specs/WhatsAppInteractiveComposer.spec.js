import { shallowMount } from '@vue/test-utils';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import WhatsAppInteractiveComposer from '../WhatsAppInteractiveComposer.vue';

const limits = {
  bodyMaxLength: 1024,
  buttonTitleMaxLength: 20,
  buttonMinCount: 1,
  buttonMaxCount: 3,
};

const mountComposer = modelValue =>
  shallowMount(WhatsAppInteractiveComposer, {
    props: { modelValue, limits },
    global: { mocks: { $t: key => key } },
  });

describe('WhatsAppInteractiveComposer', () => {
  it('applies the server-provided limits and emits only editable fields', async () => {
    const wrapper = mountComposer({
      body: 'Choose one.',
      buttons: ['Confirm'],
    });

    expect(wrapper.findComponent(TextArea).props('maxLength')).toBe(1024);
    expect(wrapper.findComponent(Input).attributes('maxlength')).toBe('20');

    await wrapper
      .findComponent(TextArea)
      .vm.$emit('update:modelValue', 'Updated prompt');
    await wrapper
      .findComponent(Input)
      .vm.$emit('update:modelValue', 'Continue');

    expect(wrapper.emitted('update:modelValue')).toEqual([
      [{ body: 'Updated prompt', buttons: ['Confirm'] }],
      [{ body: 'Choose one.', buttons: ['Continue'] }],
    ]);
  });

  it('enforces the configured button count in its controls', () => {
    const oneButton = mountComposer({ body: 'Choose one.', buttons: ['One'] });
    const threeButtons = mountComposer({
      body: 'Choose one.',
      buttons: ['One', 'Two', 'Three'],
    });

    expect(
      oneButton
        .findAllComponents(Button)
        .some(
          button =>
            button.props('label') ===
            'CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.ADD_BUTTON'
        )
    ).toBe(true);
    expect(
      threeButtons
        .findAllComponents(Button)
        .some(
          button =>
            button.props('label') ===
            'CONVERSATION.REPLYBOX.WHATSAPP_BUTTONS.ADD_BUTTON'
        )
    ).toBe(false);
    expect(oneButton.findAllComponents(Input)).toHaveLength(1);
    expect(threeButtons.findAllComponents(Input)).toHaveLength(3);
  });
});
