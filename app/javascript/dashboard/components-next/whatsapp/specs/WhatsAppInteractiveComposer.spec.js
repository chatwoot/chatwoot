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

const capabilities = {
  button: { implemented: true, available: true },
  list: { implemented: true, available: true },
};

const mountComposer = (modelValue, props = {}) =>
  shallowMount(WhatsAppInteractiveComposer, {
    props: {
      modelValue,
      limits,
      type: 'button',
      capabilities,
      ...props,
    },
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

  it('shows current type availability and test-mode guidance', () => {
    const wrapper = mountComposer(
      { body: 'Choose', buttons: ['One'] },
      {
        accountMode: 'test',
        capabilities: {
          button: { implemented: true, available: true },
          list: {
            implemented: true,
            available: false,
            unavailable_reason: 'service_window_closed',
          },
        },
      }
    );

    expect(wrapper.find('[data-testid="whatsapp-test-mode"]').exists()).toBe(
      true
    );
    expect(
      wrapper.find('[data-testid="whatsapp-unavailable-list"]').text()
    ).toBe(
      'CONVERSATION.REPLYBOX.WHATSAPP_INTERACTIVE.UNAVAILABLE.service_window_closed'
    );
    expect(wrapper.find('input[value="list"]').attributes('disabled')).toBe('');
  });

  it('shows normalized list limits without restricting raw input length', () => {
    const listLimits = {
      bodyMaxLength: 4096,
      headerMaxLength: 60,
      footerMaxLength: 60,
      buttonMaxLength: 20,
      sectionMinCount: 1,
      sectionMaxCount: 10,
      rowMinCount: 1,
      rowMaxCount: 10,
      sectionTitleMaxLength: 24,
      rowTitleMaxLength: 24,
      rowDescriptionMaxLength: 72,
    };
    const modelValue = {
      header: ` ${'h'.repeat(60)} `,
      body: ` ${'b'.repeat(4096)} `,
      footer: ` ${'f'.repeat(60)} `,
      button: ` ${'o'.repeat(20)} `,
      sections: [
        {
          title: ` ${'s'.repeat(24)} `,
          rows: [
            {
              title: ` ${'t'.repeat(24)} `,
              description: ` ${'d'.repeat(72)} `,
            },
          ],
        },
      ],
    };
    const wrapper = mountComposer(modelValue, {
      type: 'list',
      limits: listLimits,
    });

    expect(wrapper.findComponent(TextArea).props()).toMatchObject({
      maxLength: 4096,
      showCharacterCount: false,
      message: '4096/4096',
    });
    expect(
      wrapper.find('#whatsapp-interactive-list-button').attributes('maxlength')
    ).toBeUndefined();
    expect(
      wrapper.find('#whatsapp-list-section-title-0').attributes('maxlength')
    ).toBeUndefined();
    expect(
      wrapper.find('#whatsapp-list-row-title-0-0').attributes('maxlength')
    ).toBeUndefined();
    expect(
      wrapper.find('#whatsapp-list-row-description-0-0').attributes('maxlength')
    ).toBeUndefined();
    expect(
      wrapper.find('#whatsapp-interactive-list-header').attributes('maxlength')
    ).toBeUndefined();
    expect(
      wrapper.find('#whatsapp-interactive-footer').attributes('maxlength')
    ).toBeUndefined();
    expect(
      wrapper.find('#whatsapp-interactive-list-button').attributes('message')
    ).toBe('20/20');
    expect(
      wrapper.findComponent({ name: 'WhatsAppInteractivePreview' }).props()
    ).toMatchObject({
      type: 'list',
      body: ` ${'b'.repeat(4096)} `,
      header: { type: 'text', text: ` ${'h'.repeat(60)} ` },
      footer: ` ${'f'.repeat(60)} `,
      opener: ` ${'o'.repeat(20)} `,
      sections: modelValue.sections,
    });
  });

  it('stops adding list rows and sections at ten total rows', () => {
    const rows = Array.from({ length: 10 }, (_, index) => ({
      title: `Row ${index + 1}`,
      description: '',
    }));
    const wrapper = mountComposer(
      {
        header: '',
        body: 'Choose',
        footer: '',
        button: 'Open',
        sections: [{ title: '', rows }],
      },
      {
        type: 'list',
        limits: {
          bodyMaxLength: 4096,
          headerMaxLength: 60,
          footerMaxLength: 60,
          buttonMaxLength: 20,
          sectionMinCount: 1,
          sectionMaxCount: 10,
          rowMinCount: 1,
          rowMaxCount: 10,
          sectionTitleMaxLength: 24,
          rowTitleMaxLength: 24,
          rowDescriptionMaxLength: 72,
        },
      }
    );

    const labels = wrapper
      .findAllComponents(Button)
      .map(button => button.props('label'));
    expect(labels).not.toContain('CONVERSATION.REPLYBOX.WHATSAPP_LIST.ADD_ROW');
    expect(labels).not.toContain(
      'CONVERSATION.REPLYBOX.WHATSAPP_LIST.ADD_SECTION'
    );
  });
});
