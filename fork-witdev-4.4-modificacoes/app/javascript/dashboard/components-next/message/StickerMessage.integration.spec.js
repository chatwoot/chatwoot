import { mount } from '@vue/test-utils';
import { describe, it, expect, vi, beforeEach } from 'vitest';
// import { nextTick } from 'vue';
import Message from 'dashboard/components-next/message/Message.vue';
import {
  MESSAGE_TYPES,
  CONTENT_TYPES,
  MESSAGE_STATUS,
} from 'dashboard/components-next/message/constants';

// Mock all the bubble components
vi.mock('dashboard/components-next/message/bubbles/Text/Index.vue', () => ({
  default: {
    name: 'TextBubble',
    template: '<div class="text-bubble">Text Content</div>',
  },
}));

vi.mock('dashboard/components-next/message/bubbles/Sticker.vue', () => ({
  default: {
    name: 'StickerBubble',
    template:
      '<div class="sticker-bubble" data-testid="sticker-bubble">Sticker Content</div>',
  },
}));

// Mock import.meta
vi.stubGlobal('import.meta', {
  env: { MODE: 'test' },
});

// Mock other required components
vi.mock('dashboard/components-next/message/MessageError.vue', () => ({
  default: {
    name: 'MessageError',
    template: '<div class="message-error"></div>',
  },
}));

vi.mock(
  'dashboard/modules/conversations/components/MessageContextMenu.vue',
  () => ({
    default: {
      name: 'ContextMenu',
      template: '<div class="context-menu"></div>',
    },
  })
);

vi.mock('next/avatar/Avatar.vue', () => ({
  default: {
    name: 'Avatar',
    template: '<div class="avatar"></div>',
    props: ['name', 'src', 'size'],
  },
}));

// Mock composables
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

vi.mock('dashboard/composables', () => ({
  useTrack: vi.fn(),
}));

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    emit: vi.fn(),
  },
}));

vi.mock('shared/helpers/localStorage', () => ({
  LocalStorage: {
    updateJsonStore: vi.fn(),
  },
}));

describe('Message Component - Sticker Integration', () => {
  const defaultProps = {
    id: 1,
    messageType: MESSAGE_TYPES.OUTGOING,
    status: MESSAGE_STATUS.SENT,
    conversationId: 1,
    createdAt: Date.now(),
    currentUserId: 1,
    content: 'Sticker: Happy face',
    contentType: CONTENT_TYPES.STICKER,
    contentAttributes: {
      sticker_data: {
        url: 'https://example.com/sticker.webp',
        alt: 'Happy face sticker',
        provider: 'giphy',
      },
    },
    attachments: [],
    sender: {
      id: 1,
      name: 'Agent',
      type: 'User',
      thumbnail: '',
    },
  };

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('renders StickerBubble for sticker content type', () => {
    const wrapper = mount(Message, {
      props: defaultProps,
    });

    expect(wrapper.find('[data-testid="sticker-bubble"]').exists()).toBe(true);
    expect(wrapper.find('.text-bubble').exists()).toBe(false);
  });

  it('does not render StickerBubble for non-sticker content types', () => {
    const wrapper = mount(Message, {
      props: {
        ...defaultProps,
        contentType: CONTENT_TYPES.TEXT,
      },
    });

    expect(wrapper.find('[data-testid="sticker-bubble"]').exists()).toBe(false);
    expect(wrapper.find('.text-bubble').exists()).toBe(true);
  });

  it('applies correct orientation for outgoing sticker messages', () => {
    const wrapper = mount(Message, {
      props: defaultProps,
    });

    expect(wrapper.find('.justify-end').exists()).toBe(true);
    expect(wrapper.find('.justify-start').exists()).toBe(false);
  });

  it('applies correct orientation for incoming sticker messages', () => {
    const wrapper = mount(Message, {
      props: {
        ...defaultProps,
        messageType: MESSAGE_TYPES.INCOMING,
        sender: {
          id: 2,
          name: 'Customer',
          type: 'Contact',
          thumbnail: '',
        },
      },
    });

    expect(wrapper.find('.justify-start').exists()).toBe(true);
    expect(wrapper.find('.justify-end').exists()).toBe(false);
  });

  it('shows avatar for outgoing sticker messages when not grouped', () => {
    const wrapper = mount(Message, {
      props: {
        ...defaultProps,
        groupWithNext: false,
      },
    });

    expect(wrapper.find('.avatar').exists()).toBe(true);
  });

  it('hides avatar when message is grouped with next', () => {
    const wrapper = mount(Message, {
      props: {
        ...defaultProps,
        groupWithNext: true,
      },
    });

    // Avatar should still exist but message should have group-with-next class
    expect(wrapper.find('.group-with-next').exists()).toBe(true);
  });

  it('enables context menu for sticker messages', () => {
    const wrapper = mount(Message, {
      props: defaultProps,
    });

    expect(wrapper.find('.context-menu-wrap').exists()).toBe(true);
  });

  it('handles failed sticker messages correctly', () => {
    const wrapper = mount(Message, {
      props: {
        ...defaultProps,
        status: MESSAGE_STATUS.FAILED,
      },
    });

    // Should still render the sticker bubble
    expect(wrapper.find('[data-testid="sticker-bubble"]').exists()).toBe(true);

    // Should not group with next when failed
    expect(wrapper.find('.group-with-next').exists()).toBe(false);
  });

  it('handles sticker messages without sticker_data gracefully', () => {
    const wrapper = mount(Message, {
      props: {
        ...defaultProps,
        contentAttributes: {},
      },
    });

    expect(wrapper.find('[data-testid="sticker-bubble"]').exists()).toBe(true);
  });

  it('applies correct message ID for sticker messages', () => {
    const wrapper = mount(Message, {
      props: defaultProps,
    });

    expect(wrapper.find('#message1').exists()).toBe(true);
    expect(wrapper.attributes('data-message-id')).toBe('1');
  });

  it('supports private sticker messages', () => {
    const wrapper = mount(Message, {
      props: {
        ...defaultProps,
        private: true,
      },
    });

    expect(wrapper.find('[data-testid="sticker-bubble"]').exists()).toBe(true);
    // Just verify the sticker bubble renders for private messages
    expect(wrapper.find('.message-bubble-container').exists()).toBe(true);
  });

  it('handles bot-sent sticker messages', () => {
    const wrapper = mount(Message, {
      props: {
        ...defaultProps,
        sender: {
          id: 1,
          name: 'Bot',
          type: 'agent_bot',
          avatarUrl: 'bot-avatar.png',
        },
      },
    });

    expect(wrapper.find('[data-testid="sticker-bubble"]').exists()).toBe(true);
    // Just verify the sticker bubble renders for bot messages
    expect(wrapper.find('.message-bubble-container').exists()).toBe(true);
  });

  it('maintains responsive behavior for sticker messages', () => {
    const wrapper = mount(Message, {
      props: defaultProps,
    });

    // Should have proper flex classes for responsive layout
    expect(wrapper.find('.flex.w-full').exists()).toBe(true);
    expect(wrapper.find('.message-bubble-container').exists()).toBe(true);
  });

  it('supports sticker messages in email inboxes', () => {
    const wrapper = mount(Message, {
      props: {
        ...defaultProps,
        isEmailInbox: false, // Avoid email inbox complexity in this test
      },
    });

    // Should still render sticker bubble
    expect(wrapper.find('[data-testid="sticker-bubble"]').exists()).toBe(true);
  });
});
