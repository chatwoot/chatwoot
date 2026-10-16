import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import Activity from '../Activity.vue';
import { provideMessageContext } from '../../provider.js';

const maliciousContent =
  'Conversation was resolved by <img src="https://example.com/tracker.png" onerror="alert(1)">Agent';

const mountActivity = () => {
  const TestHost = defineComponent({
    components: { Activity },
    setup() {
      provideMessageContext({
        content: ref(maliciousContent),
        createdAt: ref(1_723_456_789),
      });
    },
    template: '<Activity />',
  });

  return mount(TestHost, {
    global: {
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
});
