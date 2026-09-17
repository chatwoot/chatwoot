import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { withFullI18n } from 'test-i18n';
import ForwardedEmailBanner from '../ForwardedEmailBanner.vue';
import { provideMessageContext } from '../../provider.js';

withFullI18n();

const mountBanner = ({ toEmails, contact }) => {
  const Host = defineComponent({
    components: { ForwardedEmailBanner },
    setup() {
      provideMessageContext({ contentAttributes: ref({ toEmails }) });
    },
    template: '<ForwardedEmailBanner />',
  });

  const store = createStore({
    getters: {
      getSelectedChat: () => ({ meta: { sender: contact } }),
      getSelectedChatAttachments: () => [],
    },
  });

  return mount(Host, {
    global: { plugins: [store], stubs: { Icon: true } },
  });
};

describe('ForwardedEmailBanner', () => {
  it('tells the agent who received the forward and that the contact cannot see it', () => {
    const wrapper = mountBanner({
      toEmails: ['vendor@example.com', 'ops@example.com'],
      contact: { name: 'Jane', email: 'jane@example.com' },
    });

    expect(wrapper.text()).toContain(
      'Forwarded to vendor@example.com, ops@example.com'
    );
    expect(wrapper.text()).toContain('Jane cannot see this');
  });

  it('drops the visibility note when the contact is a recipient', () => {
    const wrapper = mountBanner({
      toEmails: ['jane@example.com'],
      contact: { name: 'Jane', email: 'jane@example.com' },
    });

    expect(wrapper.text()).toContain('Forwarded to jane@example.com');
    expect(wrapper.text()).not.toContain('cannot see this');
  });
});
