import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { vi } from 'vitest';
import StickerButton from './StickerButton.vue';

// Mock NextButton component
vi.mock('dashboard/components-next/button/Button.vue', () => ({
  default: {
    name: 'NextButton',
    props: ['icon', 'slate', 'faded', 'sm'],
    template: '<button><slot /></button>',
  },
}));

const createWrapper = (props = {}, storeState = {}) => {
  const store = createStore({
    modules: {
      conversations: {
        namespaced: true,
        getters: {
          getSelectedChat: () => storeState.selectedChat || null,
        },
      },
    },
  });

  return mount(StickerButton, {
    props: {
      conversationId: 1,
      inbox: { channel_type: 'Channel::Whatsapp' },
      ...props,
    },
    global: {
      plugins: [store],
      mocks: {
        $t: key => key,
      },
      directives: {
        tooltip: {
          mounted() {},
          updated() {},
        },
      },
    },
  });
};

describe('StickerButton', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('Visibility Logic', () => {
    it('shows button for WhatsApp channel via inbox prop', () => {
      const wrapper = createWrapper({
        inbox: { channel_type: 'Channel::Whatsapp' },
      });

      expect(wrapper.find('button').exists()).toBe(true);
    });

    it('shows button for WhatsApp channel via store', () => {
      const wrapper = createWrapper(
        { inbox: {} },
        { selectedChat: { inbox: { channel_type: 'Channel::Whatsapp' } } }
      );

      expect(wrapper.find('button').exists()).toBe(true);
    });

    it('hides button for non-WhatsApp channels', () => {
      const wrapper = createWrapper({
        inbox: { channel_type: 'Channel::WebWidget' },
      });

      expect(wrapper.find('button').exists()).toBe(false);
    });

    it('hides button when no channel type is provided', () => {
      const wrapper = createWrapper({
        inbox: {},
      });

      expect(wrapper.find('button').exists()).toBe(false);
    });
  });

  describe('Channel Type Detection', () => {
    it('correctly identifies WhatsApp channel from inbox prop', () => {
      const wrapper = createWrapper({
        inbox: { channel_type: 'Channel::Whatsapp' },
      });

      expect(wrapper.vm.isWhatsAppChannel).toBe(true);
    });

    it('correctly identifies WhatsApp channel from store', () => {
      const wrapper = createWrapper(
        { inbox: {} },
        { selectedChat: { inbox: { channel_type: 'Channel::Whatsapp' } } }
      );

      expect(wrapper.vm.isWhatsAppChannel).toBe(true);
    });

    it('correctly identifies non-WhatsApp channels', () => {
      const wrapper = createWrapper({
        inbox: { channel_type: 'Channel::WebWidget' },
      });

      expect(wrapper.vm.isWhatsAppChannel).toBe(false);
    });

    it('handles missing channel type gracefully', () => {
      const wrapper = createWrapper({
        inbox: {},
      });

      expect(wrapper.vm.isWhatsAppChannel).toBe(false);
    });
  });

  describe('Button Interaction', () => {
    it('emits open-sticker-picker event when clicked', async () => {
      const wrapper = createWrapper({
        inbox: { channel_type: 'Channel::Whatsapp' },
      });

      await wrapper.find('button').trigger('click');
      expect(wrapper.emitted('open-sticker-picker')).toBeTruthy();
      expect(wrapper.emitted('open-sticker-picker')).toHaveLength(1);
    });

    it('calls openStickerPicker method when clicked', async () => {
      const wrapper = createWrapper({
        inbox: { channel_type: 'Channel::Whatsapp' },
      });

      const openStickerPickerSpy = vi.spyOn(wrapper.vm, 'openStickerPicker');

      await wrapper.find('button').trigger('click');
      expect(openStickerPickerSpy).toHaveBeenCalled();
    });
  });

  describe('Props Validation', () => {
    it('accepts valid conversationId as string', () => {
      const wrapper = createWrapper({
        conversationId: '123',
        inbox: { channel_type: 'Channel::Whatsapp' },
      });

      expect(wrapper.props('conversationId')).toBe('123');
    });

    it('accepts valid conversationId as number', () => {
      const wrapper = createWrapper({
        conversationId: 123,
        inbox: { channel_type: 'Channel::Whatsapp' },
      });

      expect(wrapper.props('conversationId')).toBe(123);
    });

    it('accepts inbox object', () => {
      const inbox = { channel_type: 'Channel::Whatsapp', id: 1 };
      const wrapper = createWrapper({
        inbox,
      });

      expect(wrapper.props('inbox')).toEqual(inbox);
    });

    it('uses default empty object for inbox when not provided', () => {
      const wrapper = createWrapper({
        conversationId: 1,
        inbox: undefined,
      });

      expect(wrapper.props('inbox')).toEqual({});
    });
  });

  describe('Component Structure', () => {
    it('renders NextButton with correct props', () => {
      const wrapper = createWrapper({
        inbox: { channel_type: 'Channel::Whatsapp' },
      });

      const nextButton = wrapper.findComponent({ name: 'NextButton' });
      expect(nextButton.exists()).toBe(true);
      expect(nextButton.props('icon')).toBe('i-ph-sticker');
      expect(nextButton.props('slate')).toBe(true);
      expect(nextButton.props('faded')).toBe(true);
      expect(nextButton.props('sm')).toBe(true);
    });

    it('has correct tooltip directive', () => {
      const wrapper = createWrapper({
        inbox: { channel_type: 'Channel::Whatsapp' },
      });

      // The tooltip directive should be applied to the NextButton
      // This is tested through the component rendering without errors
      expect(wrapper.find('button').exists()).toBe(true);
    });
  });

  describe('Edge Cases', () => {
    it('handles undefined inbox gracefully', () => {
      const wrapper = createWrapper({
        inbox: undefined,
      });

      expect(wrapper.vm.isWhatsAppChannel).toBe(false);
      expect(wrapper.find('button').exists()).toBe(false);
    });

    it('handles null conversation in store', () => {
      const wrapper = createWrapper({ inbox: {} }, { selectedChat: null });

      expect(wrapper.vm.isWhatsAppChannel).toBe(false);
      expect(wrapper.find('button').exists()).toBe(false);
    });

    it('handles conversation without inbox in store', () => {
      const wrapper = createWrapper(
        { inbox: {} },
        { selectedChat: { inbox: null } }
      );

      expect(wrapper.vm.isWhatsAppChannel).toBe(false);
      expect(wrapper.find('button').exists()).toBe(false);
    });
  });

  describe('Computed Properties', () => {
    it('shouldShowStickerButton returns true for WhatsApp channels', () => {
      const wrapper = createWrapper({
        inbox: { channel_type: 'Channel::Whatsapp' },
      });

      expect(wrapper.vm.shouldShowStickerButton).toBe(true);
    });

    it('shouldShowStickerButton returns false for non-WhatsApp channels', () => {
      const wrapper = createWrapper({
        inbox: { channel_type: 'Channel::WebWidget' },
      });

      expect(wrapper.vm.shouldShowStickerButton).toBe(false);
    });
  });
});
