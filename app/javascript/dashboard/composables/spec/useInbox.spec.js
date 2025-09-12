import { describe, it, expect, vi } from 'vitest';
import { defineComponent, h } from 'vue';
import { createStore } from 'vuex';
import { mount } from '@vue/test-utils';
import { useInbox } from '../useInbox';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables/useTransformKeys');

// Mock the dependencies
const mockStore = createStore({
  modules: {
    conversations: {
      namespaced: false,
      getters: {
        getSelectedChat: () => ({ inbox_id: 1 }),
      },
    },
    inboxes: {
      namespaced: true,
      getters: {
        getInboxById: () => id => {
          const inboxes = {
            1: {
              id: 1,
              channel_type: INBOX_TYPES.WHATSAPP,
              provider: 'whatsapp_cloud',
            },
            2: { id: 2, channel_type: INBOX_TYPES.FB },
            3: { id: 3, channel_type: INBOX_TYPES.TWILIO, medium: 'sms' },
            4: { id: 4, channel_type: INBOX_TYPES.TWILIO, medium: 'whatsapp' },
            5: {
              id: 5,
              channel_type: INBOX_TYPES.EMAIL,
              provider: 'microsoft',
            },
            6: { id: 6, channel_type: INBOX_TYPES.EMAIL, provider: 'google' },
            7: {
              id: 7,
              channel_type: INBOX_TYPES.WHATSAPP,
              provider: 'default',
            },
            8: { id: 8, channel_type: INBOX_TYPES.TELEGRAM },
            9: { id: 9, channel_type: INBOX_TYPES.LINE },
            10: { id: 10, channel_type: INBOX_TYPES.WEB },
            11: { id: 11, channel_type: INBOX_TYPES.API },
            12: { id: 12, channel_type: INBOX_TYPES.SMS },
            13: { id: 13, channel_type: INBOX_TYPES.INSTAGRAM },
            14: { id: 14, channel_type: INBOX_TYPES.VOICE },
          };
          return inboxes[id] || null;
        },
      },
    },
  },
});

// Mock useMapGetter to return mock store getters
vi.mock('dashboard/composables/store', () => ({
  useMapGetter: vi.fn(getter => {
    if (getter === 'getSelectedChat') {
      return { value: { inbox_id: 1 } };
    }
    if (getter === 'inboxes/getInboxById') {
      return { value: mockStore.getters['inboxes/getInboxById'] };
    }
    return { value: null };
  }),
}));

// Mock useCamelCase to return the data as-is for testing
vi.mock('dashboard/composables/useTransformKeys', () => ({
  useCamelCase: vi.fn(data => ({
    ...data,
    channelType: data?.channel_type,
  })),
}));

describe('useInbox', () => {
  const createTestComponent = inboxId =>
    defineComponent({
      setup() {
        return useInbox(inboxId);
      },
      render() {
        return h('div');
      },
    });

  describe('with current chat context (no inboxId provided)', () => {
    it('identifies WhatsApp Cloud channel correctly', () => {
      const wrapper = mount(createTestComponent(), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.isAWhatsAppCloudChannel).toBe(true);
      expect(wrapper.vm.isAWhatsAppChannel).toBe(true);
    });

    it('returns correct inbox object', () => {
      const wrapper = mount(createTestComponent(), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.inbox).toEqual({
        id: 1,
        channel_type: INBOX_TYPES.WHATSAPP,
        provider: 'whatsapp_cloud',
        channelType: INBOX_TYPES.WHATSAPP,
      });
    });
  });

  describe('with explicit inboxId provided', () => {
    it('identifies Facebook inbox correctly', () => {
      const wrapper = mount(createTestComponent(2), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.isAFacebookInbox).toBe(true);
      expect(wrapper.vm.isAWhatsAppChannel).toBe(false);
    });

    it('identifies Twilio SMS channel correctly', () => {
      const wrapper = mount(createTestComponent(3), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.isATwilioChannel).toBe(true);
      expect(wrapper.vm.isASmsInbox).toBe(true);
      expect(wrapper.vm.isAWhatsAppChannel).toBe(false);
    });

    it('identifies Twilio WhatsApp channel correctly', () => {
      const wrapper = mount(createTestComponent(4), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.isATwilioChannel).toBe(true);
      expect(wrapper.vm.isAWhatsAppChannel).toBe(true);
      expect(wrapper.vm.isATwilioWhatsAppChannel).toBe(true);
      expect(wrapper.vm.isAWhatsAppCloudChannel).toBe(false);
    });

    it('identifies Microsoft email inbox correctly', () => {
      const wrapper = mount(createTestComponent(5), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.isAnEmailChannel).toBe(true);
      expect(wrapper.vm.isAMicrosoftInbox).toBe(true);
      expect(wrapper.vm.isAGoogleInbox).toBe(false);
    });

    it('identifies Google email inbox correctly', () => {
      const wrapper = mount(createTestComponent(6), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.isAnEmailChannel).toBe(true);
      expect(wrapper.vm.isAGoogleInbox).toBe(true);
      expect(wrapper.vm.isAMicrosoftInbox).toBe(false);
    });

    it('identifies 360Dialog WhatsApp channel correctly', () => {
      const wrapper = mount(createTestComponent(7), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.is360DialogWhatsAppChannel).toBe(true);
      expect(wrapper.vm.isAWhatsAppChannel).toBe(true);
      expect(wrapper.vm.isAWhatsAppCloudChannel).toBe(false);
    });

    it('identifies all other channel types correctly', () => {
      // Test Telegram
      let wrapper = mount(createTestComponent(8), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isATelegramChannel).toBe(true);

      // Test Line
      wrapper = mount(createTestComponent(9), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isALineChannel).toBe(true);

      // Test Web Widget
      wrapper = mount(createTestComponent(10), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isAWebWidgetInbox).toBe(true);

      // Test API
      wrapper = mount(createTestComponent(11), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isAPIInbox).toBe(true);

      // Test SMS
      wrapper = mount(createTestComponent(12), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isASmsInbox).toBe(true);

      // Test Instagram
      wrapper = mount(createTestComponent(13), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isAnInstagramChannel).toBe(true);

      // Test Voice
      wrapper = mount(createTestComponent(14), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isAVoiceChannel).toBe(true);
    });
  });

  describe('edge cases', () => {
    it('handles non-existent inbox ID gracefully', () => {
      const wrapper = mount(createTestComponent(999), {
        global: { plugins: [mockStore] },
      });

      // useCamelCase still processes null data, so we get an object with channelType: undefined
      expect(wrapper.vm.inbox).toEqual({ channelType: undefined });
      expect(wrapper.vm.isAWhatsAppChannel).toBe(false);
      expect(wrapper.vm.isAFacebookInbox).toBe(false);
    });

    it('handles inbox with no data correctly', () => {
      // The mock will return null for non-existent IDs, but useCamelCase processes it
      const wrapper = mount(createTestComponent(999), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.inbox.channelType).toBeUndefined();
      expect(wrapper.vm.isAWhatsAppChannel).toBe(false);
      expect(wrapper.vm.isAFacebookInbox).toBe(false);
      expect(wrapper.vm.isATelegramChannel).toBe(false);
    });
  });

  describe('return object completeness', () => {
    it('returns all expected properties', () => {
      const wrapper = mount(createTestComponent(1), {
        global: { plugins: [mockStore] },
      });

      const expectedProperties = [
        'inbox',
        'isAFacebookInbox',
        'isALineChannel',
        'isAPIInbox',
        'isASmsInbox',
        'isATelegramChannel',
        'isATwilioChannel',
        'isAWebWidgetInbox',
        'isAWhatsAppChannel',
        'isAMicrosoftInbox',
        'isAGoogleInbox',
        'isATwilioWhatsAppChannel',
        'isAWhatsAppCloudChannel',
        'is360DialogWhatsAppChannel',
        'isAnEmailChannel',
        'isAnInstagramChannel',
        'isAVoiceChannel',
      ];

      expectedProperties.forEach(prop => {
        expect(wrapper.vm).toHaveProperty(prop);
      });
    });
  });
});
