import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import BaseBubble from '../Base.vue';
import { provideMessageContext } from '../../provider.js';
import {
  MESSAGE_VARIANTS,
  ORIENTATION,
} from 'dashboard/components-next/message/constants';

describe('BaseBubble', () => {
  it('shows a readable inbound selection with its linked originating message', () => {
    const TestHost = defineComponent({
      components: { BaseBubble },
      setup() {
        provideMessageContext({
          id: ref(43),
          variant: ref(MESSAGE_VARIANTS.USER),
          orientation: ref(ORIENTATION.LEFT),
          inReplyTo: ref({ id: 42, content: 'Choose a meal.' }),
          shouldGroupWithNext: ref(false),
          sender: ref(null),
          senderType: ref('Contact'),
          contentAttributes: ref({
            whatsappInteractiveReply: {
              type: 'list_reply',
              title: 'Pasta',
              deliveryId: 'row-1',
            },
          }),
        });
        return { selection: 'Pasta' };
      },
      template:
        '<BaseBubble hide-meta><p data-testid="selection">{{ selection }}</p></BaseBubble>',
    });
    const wrapper = mount(TestHost, {
      global: {
        mocks: { $t: key => key },
        directives: {
          dompurifyHtml: {
            mounted(element, binding) {
              element.innerHTML = binding.value;
            },
          },
        },
      },
    });

    expect(wrapper.get('[data-testid="selection"]').text()).toBe('Pasta');
    expect(wrapper.text()).toContain('Choose a meal.');
  });
});
