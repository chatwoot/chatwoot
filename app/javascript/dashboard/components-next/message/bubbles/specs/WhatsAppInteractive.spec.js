import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import WhatsAppInteractive from '../WhatsAppInteractive.vue';
import { provideMessageContext } from '../../provider.js';

const mountBubble = (header = undefined, attachments = []) => {
  const TestHost = defineComponent({
    components: { WhatsAppInteractive },
    setup() {
      provideMessageContext({
        content: ref('Please choose one option.'),
        attachments: ref(attachments),
        contentAttributes: ref({
          whatsappInteractive: {
            schemaVersion: 1,
            type: 'button',
            body: { text: 'Please choose one option.' },
            header,
            footer: { text: 'Footer' },
            action: {
              buttons: [
                { deliveryId: 'reply-1', title: 'Confirm' },
                { deliveryId: 'reply-2', title: 'Change' },
              ],
            },
          },
        }),
      });
    },
    template: '<WhatsAppInteractive />',
  });

  return mount(TestHost, {
    global: {
      mocks: { $t: key => key },
      stubs: { BaseBubble: { template: '<div><slot /></div>' } },
    },
  });
};

describe('WhatsAppInteractive', () => {
  it('renders the persisted body and reply labels as disabled controls', () => {
    const wrapper = mountBubble();
    const buttons = wrapper.findAll('button');

    expect(wrapper.text()).toContain('Please choose one option.');
    expect(wrapper.text()).toContain('Footer');
    expect(buttons.map(button => button.text())).toEqual(['Confirm', 'Change']);
    expect(
      buttons.every(button => button.attributes('disabled') !== undefined)
    ).toBe(true);
  });

  it('renders the persisted text header', () => {
    expect(mountBubble({ type: 'text', text: 'Header' }).text()).toContain(
      'Header'
    );
  });

  it.each(['image', 'video', 'document'])(
    'renders the %s header using the snapshot attachment ID',
    type => {
      const wrapper = mountBubble({ type, attachmentId: 22 }, [
        { id: 11, dataUrl: 'https://example.com/wrong.png' },
        { id: 22, dataUrl: 'https://example.com/header.pdf' },
      ]);
      const media = wrapper.find(
        { image: 'img', video: 'video', document: 'a' }[type]
      );
      expect(media.attributes(type === 'document' ? 'href' : 'src')).toBe(
        'https://example.com/header.pdf'
      );
      if (type === 'document') expect(media.text()).toBe('header.pdf');
    }
  );

  it('does not display an unrelated attachment as the header', () => {
    const wrapper = mountBubble({ type: 'image', attachmentId: 22 }, [
      { id: 11, dataUrl: 'https://example.com/wrong.png' },
    ]);
    expect(wrapper.find('img').exists()).toBe(false);
  });
});
