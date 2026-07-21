import { mount } from '@vue/test-utils';
import { describe, it, expect, vi } from 'vitest';
import Message from '../Message.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({
    t: key => key,
  }),
}));

vi.mock('vue-router', () => ({
  useRoute: () => ({
    query: {},
  }),
}));

vi.mock('dashboard/composables/store', () => ({
  useMapGetter: () => () => ({}),
  useStoreGetters: () => ({
    getUISettings: { value: {} },
  }),
  useStore: () => ({
    dispatch: vi.fn(),
  }),
}));

vi.mock('dashboard/composables', () => ({
  useTrack: vi.fn(),
}));

describe('Message.vue Sender Name Header', () => {
  const defaultProps = {
    id: 1,
    messageType: 1,
    status: 'sent',
    content: 'hello world',
    conversationId: 100,
    createdAt: 123456789,
    currentUserId: 10,
    sender: { id: 10, name: 'John', type: 'user' },
    senderId: 10,
    senderType: 'user',
  };

  it('renders sender name with (You) tag for current user message', () => {
    const wrapper = mount(Message, {
      props: defaultProps,
      global: {
        stubs: {
          Avatar: true,
          MessageError: true,
          ContextMenu: true,
        },
      },
    });

    expect(wrapper.text()).toContain('John (You)');
  });

  it('renders only sender name when message is from another agent', () => {
    const wrapper = mount(Message, {
      props: {
        ...defaultProps,
        currentUserId: 10,
        sender: { id: 20, name: 'Samantha', type: 'user' },
        senderId: 20,
      },
      global: {
        stubs: {
          Avatar: true,
          MessageError: true,
          ContextMenu: true,
        },
      },
    });

    expect(wrapper.text()).toContain('Samantha');
    expect(wrapper.text()).not.toContain('Samantha (You)');
  });
});
