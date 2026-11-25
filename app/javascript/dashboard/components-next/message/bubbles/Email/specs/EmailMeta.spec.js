import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import EmailMeta from '../EmailMeta.vue';
import { provideMessageContext } from '../../../provider.js';

const mountMeta = sender => {
  const Host = defineComponent({
    components: { EmailMeta },
    setup() {
      provideMessageContext({
        contentAttributes: ref({
          email: { from: ['support@example.com'], subject: 'Re: order' },
        }),
        status: ref('sent'),
        sender: ref(sender),
      });
    },
    template: '<EmailMeta />',
  });

  return mount(Host, { global: { mocks: { $t: key => key } } });
};

describe('EmailMeta', () => {
  // A reply someone wrote from the inbox's own mailbox reaches the dashboard with no sender:
  // nobody sent it through Chatwoot.
  it('renders an email that has no sender', () => {
    const wrapper = mountMeta(null);

    expect(wrapper.text()).toContain('support@example.com');
    expect(wrapper.text()).toContain('Re: order');
  });

  it('names the sender when the email comes from them', () => {
    const wrapper = mountMeta({ name: 'Ana', email: 'support@example.com' });

    expect(wrapper.text()).toContain('Ana');
  });
});
