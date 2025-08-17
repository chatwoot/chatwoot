import { shallowMount } from '@vue/test-utils';
import { vi } from 'vitest';
import MessagesView from '../MessagesView.vue';

// Mock the composables
vi.mock('dashboard/composables/useConfig', () => ({
  useConfig: () => ({
    isEnterprise: false,
  }),
}));

vi.mock('dashboard/composables/useKeyboardEvents', () => ({
  useKeyboardEvents: vi.fn(),
}));

vi.mock('dashboard/composables/useAI', () => ({
  useAI: () => ({
    isAIIntegrationEnabled: false,
    isLabelSuggestionFeatureEnabled: false,
    fetchIntegrationsIfRequired: vi.fn(),
    fetchLabelSuggestions: vi.fn(),
  }),
}));

// Mock the store
const mockStore = {
  getters: {
    getSelectedChat: {
      id: 1,
      inbox_id: 1,
      status: 'open',
      can_reply: false,
      messages: [],
      agent_last_seen_at: null,
      unread_count: 0,
    },
    getCurrentUserID: 1,
    getAllMessagesLoaded: true,
    getCurrentAccountId: 1,
    'inboxes/getInbox': () => ({
      id: 1,
      channel_type: 'Channel::Whatsapp',
      provider: 'whapi',
    }),
    'conversationTypingStatus/getUserList': () => [],
  },
  dispatch: vi.fn(),
};

const mountParams = {
  global: {
    mocks: {
      $store: mockStore,
      $t: key => key,
      $route: { query: {} },
      $nextTick: vi.fn(),
    },
    stubs: {
      MessageList: true,
      ReplyBox: true,
      Banner: true,
      ConversationLabelSuggestion: true,
      Spinner: true,
    },
  },
};

describe('MessagesView.vue', () => {
  describe('replyWindowBannerMessage', () => {
    it('returns empty string for WHAPI channels (no 24-hour restriction)', () => {
      const wrapper = shallowMount(MessagesView, {
        ...mountParams,
        global: {
          ...mountParams.global,
          mocks: {
            ...mountParams.global.mocks,
            $store: {
              ...mockStore,
              getters: {
                ...mockStore.getters,
                'inboxes/getInbox': () => ({
                  id: 1,
                  channel_type: 'Channel::Whatsapp',
                  provider: 'whapi',
                }),
              },
            },
          },
        },
      });

      expect(wrapper.vm.replyWindowBannerMessage).toBe(
        'CONVERSATION.CANNOT_REPLY'
      );
    });

    it('returns restriction message for WhatsApp Cloud channels', () => {
      const wrapper = shallowMount(MessagesView, {
        ...mountParams,
        global: {
          ...mountParams.global,
          mocks: {
            ...mountParams.global.mocks,
            $store: {
              ...mockStore,
              getters: {
                ...mockStore.getters,
                'inboxes/getInbox': () => ({
                  id: 1,
                  channel_type: 'Channel::Whatsapp',
                  provider: 'whatsapp_cloud',
                }),
              },
            },
          },
        },
      });

      expect(wrapper.vm.replyWindowBannerMessage).toBe(
        'CONVERSATION.TWILIO_WHATSAPP_CAN_REPLY'
      );
    });

    it('returns restriction message for 360Dialog channels', () => {
      const wrapper = shallowMount(MessagesView, {
        ...mountParams,
        global: {
          ...mountParams.global,
          mocks: {
            ...mountParams.global.mocks,
            $store: {
              ...mockStore,
              getters: {
                ...mockStore.getters,
                'inboxes/getInbox': () => ({
                  id: 1,
                  channel_type: 'Channel::Whatsapp',
                  provider: 'default',
                }),
              },
            },
          },
        },
      });

      expect(wrapper.vm.replyWindowBannerMessage).toBe(
        'CONVERSATION.TWILIO_WHATSAPP_CAN_REPLY'
      );
    });
  });

  describe('replyWindowLinkText', () => {
    it('returns empty string for WHAPI channels (no 24-hour restriction)', () => {
      const wrapper = shallowMount(MessagesView, {
        ...mountParams,
        global: {
          ...mountParams.global,
          mocks: {
            ...mountParams.global.mocks,
            $store: {
              ...mockStore,
              getters: {
                ...mockStore.getters,
                'inboxes/getInbox': () => ({
                  id: 1,
                  channel_type: 'Channel::Whatsapp',
                  provider: 'whapi',
                }),
              },
            },
          },
        },
      });

      expect(wrapper.vm.replyWindowLinkText).toBe('');
    });

    it('returns 24-hour window text for WhatsApp Cloud channels', () => {
      const wrapper = shallowMount(MessagesView, {
        ...mountParams,
        global: {
          ...mountParams.global,
          mocks: {
            ...mountParams.global.mocks,
            $store: {
              ...mockStore,
              getters: {
                ...mockStore.getters,
                'inboxes/getInbox': () => ({
                  id: 1,
                  channel_type: 'Channel::Whatsapp',
                  provider: 'whatsapp_cloud',
                }),
              },
            },
          },
        },
      });

      expect(wrapper.vm.replyWindowLinkText).toBe(
        'CONVERSATION.24_HOURS_WINDOW'
      );
    });

    it('returns 24-hour window text for 360Dialog channels', () => {
      const wrapper = shallowMount(MessagesView, {
        ...mountParams,
        global: {
          ...mountParams.global,
          mocks: {
            ...mountParams.global.mocks,
            $store: {
              ...mockStore,
              getters: {
                ...mockStore.getters,
                'inboxes/getInbox': () => ({
                  id: 1,
                  channel_type: 'Channel::Whatsapp',
                  provider: 'default',
                }),
              },
            },
          },
        },
      });

      expect(wrapper.vm.replyWindowLinkText).toBe(
        'CONVERSATION.24_HOURS_WINDOW'
      );
    });
  });
});
