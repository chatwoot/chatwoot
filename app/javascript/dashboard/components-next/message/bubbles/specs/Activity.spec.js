import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import { createI18n } from 'vue-i18n';
import Activity from '../Activity.vue';
import { provideMessageContext } from '../../provider.js';

const maliciousContent =
  'Conversation was resolved by <img src="https://example.com/tracker.png" onerror="alert(1)">Agent';

const mountActivity = (contentAttributes = {}) => {
  const TestHost = defineComponent({
    components: { Activity },
    setup() {
      provideMessageContext({
        content: ref(maliciousContent),
        contentAttributes: ref(contentAttributes),
        createdAt: ref(1_723_456_789),
      });
    },
    template: '<Activity />',
  });

  const i18n = createI18n({
    legacy: false,
    locale: 'en',
    messages: {
      en: {
        CONVERSATION: {
          ACTIVITY: {
            ASSIGNEE: { ASSIGNED: 'Assigned to {assigneeName} by {userName}' },
          },
        },
      },
    },
  });

  return mount(TestHost, {
    global: {
      plugins: [i18n],
      stubs: {
        BaseBubble: { template: '<div><slot /></div>' },
      },
    },
  });
};

describe('Activity', () => {
  it('renders activity content as plain text', () => {
    const wrapper = mountActivity();
    const content = wrapper.find('span');

    expect(content.text()).toBe(maliciousContent);
    expect(content.find('img').exists()).toBe(false);
    expect(content.html()).toContain('&lt;img');
  });

  it('builds the sentence from the activity key and params', () => {
    const wrapper = mountActivity({
      activity: {
        key: 'assignee.assigned',
        params: { assigneeName: 'Ann', userName: 'Bob' },
      },
    });

    expect(wrapper.find('span').text()).toBe('Assigned to Ann by Bob');
  });
});
