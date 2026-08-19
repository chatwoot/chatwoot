import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import Activity from '../Activity.vue';
import { provideMessageContext } from '../../provider.js';

const mountActivity = content => {
  const TestHost = defineComponent({
    components: { Activity },
    setup() {
      provideMessageContext({
        content: ref(content),
        createdAt: ref(1724054400),
      });
    },
    template: '<Activity />',
  });

  return mount(TestHost, {
    global: {
      stubs: {
        BaseBubble: {
          template: '<div data-bubble-name="activity"><slot /></div>',
        },
      },
    },
  });
};

describe('Activity', () => {
  it('renders activity content as text instead of HTML', () => {
    const content =
      'Conversation was marked resolved by x <font color="red"><img src="https://placehold.co/80x24/red/white?text=SERA7C">SERA-HTMLi-7CM1XT2P</font>';
    const wrapper = mountActivity(content);

    expect(wrapper.text()).toContain(content);
    expect(wrapper.find('font').exists()).toBe(false);
    expect(wrapper.find('img').exists()).toBe(false);
    expect(wrapper.find('span').element.innerHTML).toContain(
      '&lt;font color="red"&gt;'
    );
    expect(wrapper.find('span').attributes('title')).toBe(content);
  });
});
