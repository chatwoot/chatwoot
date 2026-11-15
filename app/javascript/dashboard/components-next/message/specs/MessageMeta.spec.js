import { ref } from 'vue';
import { mount } from '@vue/test-utils';
import MessageMeta from '../MessageMeta.vue';
import { provideMessageContext } from '../provider.js';
import { MESSAGE_TYPES } from '../constants';

vi.mock('shared/helpers/timeHelper', () => ({
  messageTimestamp: time => `readable:${time}`,
}));
vi.mock('shared/composables/useExactTimestamp', () => ({
  useExactTimestamp: () => time => `exact:${time}`,
}));
vi.mock('dashboard/composables/useInbox', async () => {
  const { ref: makeRef } = await import('vue');
  return { useInbox: () => new Proxy({}, { get: () => makeRef(false) }) };
});

const mountMeta = contentAttributes => {
  const Host = {
    components: { MessageMeta },
    setup() {
      provideMessageContext({
        status: ref('sent'),
        isPrivate: ref(false),
        createdAt: ref(1_700_000_000),
        sourceId: ref('wamid.1'),
        messageType: ref(MESSAGE_TYPES.INCOMING),
        contentAttributes: ref(contentAttributes),
      });
    },
    template: '<MessageMeta />',
  };

  return mount(Host, {
    global: {
      directives: { tooltip: {} },
      stubs: { Icon: true, MessageStatus: true },
    },
  });
};

describe('MessageMeta', () => {
  it('shows the time the message was created in Chatwoot by default', () => {
    expect(mountMeta({}).find('time').text()).toBe('readable:1700000000');
  });

  it('shows the time reported by the channel when present', () => {
    const wrapper = mountMeta({ externalCreatedAt: 1_633_034_394 });

    expect(wrapper.find('time').text()).toBe('readable:1633034394');
  });

  it('ignores an external time that is not a valid epoch', () => {
    expect(
      mountMeta({ externalCreatedAt: 'yesterday' }).find('time').text()
    ).toBe('readable:1700000000');
  });
});
