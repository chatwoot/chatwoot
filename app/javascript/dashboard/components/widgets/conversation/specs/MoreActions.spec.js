import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import MoreActions from '../MoreActions.vue';
import FluentIcon from 'shared/components/FluentIcon/DashboardIcon.vue';

vi.mock('shared/helpers/mitt', () => ({
  emitter: {
    emit: vi.fn(),
    on: vi.fn(),
    off: vi.fn(),
  },
}));

const mockDirective = {
  mounted: () => {},
};

import { emitter } from 'shared/helpers/mitt';

describe('MoveActions', () => {
  let currentChat = { id: 8, muted: false };
  let store = null;
  let muteConversation = null;
  let unmuteConversation = null;

  beforeEach(() => {
    muteConversation = vi.fn(() => Promise.resolve());
    unmuteConversation = vi.fn(() => Promise.resolve());

    store = createStore({
      state: {
        authenticated: true,
        currentChat,
      },
      getters: {
        getSelectedChat: () => currentChat,
      },
      modules: {
        conversations: {
          namespaced: false,
          actions: { muteConversation, unmuteConversation },
        },
      },
    });
  });

  const createWrapper = () =>
    mount(MoreActions, {
      global: {
        plugins: [store],
        components: {
          'fluent-icon': FluentIcon,
        },
        directives: {
          'on-clickaway': mockDirective,
        },
      },
    });

  describe('muting discussion', () => {
    it('triggers "muteConversation"', async () => {
      const wrapper = createWrapper();
      await wrapper.find('button:first-child').trigger('click');

      expect(muteConversation).toHaveBeenCalledTimes(1);
      expect(muteConversation).toHaveBeenCalledWith(
        expect.any(Object), // First argument is the Vuex context object
        currentChat.id // Second argument is the ID of the conversation
      );
    });

    it('shows alert', async () => {
      const wrapper = createWrapper();
      await wrapper.find('button:first-child').trigger('click');

      expect(emitter.emit).toBeCalledWith('newToastMessage', {
        message:
          'This contact is blocked successfully. You will not be notified of any future conversations.',
        action: null,
      });
    });
  });

  describe('unmuting discussion', () => {
    beforeEach(() => {
      currentChat.muted = true;
    });

    it('triggers "unmuteConversation"', async () => {
      const wrapper = createWrapper();
      await wrapper.find('button:first-child').trigger('click');

      expect(unmuteConversation).toHaveBeenCalledTimes(1);
      expect(unmuteConversation).toHaveBeenCalledWith(
        expect.any(Object), // First argument is the Vuex context object
        currentChat.id // Second argument is the ID of the conversation
      );
    });

    it('shows alert', async () => {
      const wrapper = createWrapper();
      await wrapper.find('button:first-child').trigger('click');

      expect(emitter.emit).toBeCalledWith('newToastMessage', {
        message: 'This contact is unblocked successfully.',
        action: null,
      });
    });
  });
});
