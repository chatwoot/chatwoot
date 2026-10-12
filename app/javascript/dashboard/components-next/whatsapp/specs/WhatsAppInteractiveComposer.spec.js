import { shallowMount } from '@vue/test-utils';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import WhatsAppInteractiveComposer from '../WhatsAppInteractiveComposer.vue';

const limits = {
  bodyMaxLength: 1024,
  headerMaxLength: 60,
  footerMaxLength: 60,
  headerTypes: ['text', 'image', 'video', 'document'],
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
    expect(
      wrapper.find('#whatsapp-interactive-button-0').attributes('maxlength')
    ).toBe('20');

    await wrapper
      .findComponent(TextArea)
      .vm.$emit('update:modelValue', 'Updated prompt');
    await wrapper
      .findAllComponents(Input)
      .find(input => input.attributes('id') === 'whatsapp-interactive-button-0')
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
    expect(oneButton.findAllComponents(Input)).toHaveLength(2);
    expect(threeButtons.findAllComponents(Input)).toHaveLength(4);
  });

  it('offers every documented header mode and clears media on a mode change', async () => {
    const wrapper = mountComposer({
      body: 'Choose',
      buttons: ['One'],
      headerType: 'image',
      media: { name: 'old.png' },
    });
    expect(
      wrapper.findAll('option').map(option => option.attributes('value'))
    ).toEqual(['', 'text', 'image', 'video', 'document']);
    await wrapper.find('select').setValue('text');
    expect(wrapper.emitted('update:modelValue')[0][0]).toMatchObject({
      headerType: 'text',
      headerText: '',
      media: null,
      uploadFile: null,
    });
  });

  it('mirrors header/footer limits and provides a structured preview', () => {
    const wrapper = mountComposer({
      body: 'Choose',
      buttons: ['One'],
      headerType: 'text',
      headerText: 'Header',
      footer: 'Footer',
    });
    expect(
      wrapper.find('#whatsapp-interactive-header-text').attributes('maxlength')
    ).toBe('60');
    expect(
      wrapper.find('#whatsapp-interactive-footer').attributes('maxlength')
    ).toBe('60');
    expect(
      wrapper.findComponent({ name: 'WhatsAppInteractivePreview' }).props()
    ).toMatchObject({
      body: 'Choose',
      header: { type: 'text', text: 'Header' },
      footer: 'Footer',
      buttons: [{ title: 'One' }],
    });
  });

  it('emits one selected file through the ordinary upload lane', async () => {
    const wrapper = mountComposer({
      body: 'Choose',
      buttons: ['One'],
      headerType: 'image',
    });
    const file = new File(['image'], 'header.png', { type: 'image/png' });
    Object.defineProperty(wrapper.find('input[type="file"]').element, 'files', {
      value: [file],
    });
    await wrapper.find('input[type="file"]').trigger('change');
    expect(wrapper.emitted('upload')).toEqual([[file]]);
    expect(
      wrapper.find('input[type="file"]').attributes('multiple')
    ).toBeUndefined();
  });
});
