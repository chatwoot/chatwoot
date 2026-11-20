import { defineComponent, ref } from 'vue';
import { mount } from '@vue/test-utils';
import MessageMeta from '../MessageMeta.vue';
import { provideMessageContext } from '../provider.js';

vi.mock('shared/helpers/timeHelper', () => ({
  messageTimestamp: timestamp => String(timestamp),
}));

vi.mock('shared/composables/useExactTimestamp', () => ({
  useExactTimestamp: () => timestamp => String(timestamp),
}));

vi.mock('dashboard/composables/useInbox', () => ({
  useInbox: () => ({}),
}));

const mountMessageMeta = externalCreatedAt => {
  const TestHost = defineComponent({
    components: { MessageMeta },
    setup() {
      provideMessageContext({
        status: ref('sent'),
        isPrivate: ref(false),
        createdAt: ref(1_700_000_000),
        sourceId: ref(null),
        messageType: ref(0),
        contentAttributes: ref({ externalCreatedAt }),
      });
    },
    template: '<MessageMeta />',
  });

  return mount(TestHost, {
    global: { stubs: { MessageStatus: true, Icon: true } },
  });
};

describe('MessageMeta', () => {
  it('shows the external sender time when a delayed message provides one', () => {
    const wrapper = mountMessageMeta(1_664_799_904);
    expect(wrapper.find('time').text()).toBe('1664799904');
  });

  it('shows the arrival time for messages without an external sender time', () => {
    const wrapper = mountMessageMeta(undefined);
    expect(wrapper.find('time').text()).toBe('1700000000');
  });
});
