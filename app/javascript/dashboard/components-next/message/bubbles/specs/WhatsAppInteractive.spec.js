import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import WhatsAppInteractive from '../WhatsAppInteractive.vue';
import { provideMessageContext } from '../../provider.js';

const mountBubble = () => {
  const TestHost = defineComponent({
    components: { WhatsAppInteractive },
    setup() {
      provideMessageContext({
        content: ref('Please choose one option.'),
        contentAttributes: ref({
          whatsappInteractive: {
            schemaVersion: 1,
            type: 'button',
            body: { text: 'Please choose one option.' },
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
      stubs: { BaseBubble: { template: '<div><slot /></div>' } },
    },
  });
};

describe('WhatsAppInteractive', () => {
  it('renders the persisted body and reply labels as disabled controls', () => {
    const wrapper = mountBubble();
    const buttons = wrapper.findAll('button');

    expect(wrapper.text()).toContain('Please choose one option.');
    expect(buttons.map(button => button.text())).toEqual(['Confirm', 'Change']);
    expect(
      buttons.every(button => button.attributes('disabled') !== undefined)
    ).toBe(true);
  });
});
