import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import VueI18n from 'vue-i18n';
import VTooltip from 'v-tooltip';

import Button from 'dashboard/components/buttons/Button';
import i18n from 'dashboard/i18n';

import MoreActions from '../MoreActions';

const localVue = createLocalVue();
localVue.use(Vuex);
localVue.use(VueI18n);
localVue.use(VTooltip);

localVue.component('woot-button', Button);

const i18nConfig = new VueI18n({
  locale: 'en',
  messages: i18n,
});

describe('MoveActions', () => {
  let currentChat = { id: 8, muted: false };
  let state = null;
  let muteConversation = null;
  let unmuteConversation = null;
  let modules = null;
  let getters = null;
  let store = null;
  let moreActions = null;

  beforeEach(() => {
    window.bus = {
      $emit: jest.fn(),
    };

    state = {
      authenticated: true,
      currentChat,
    };

    muteConversation = jest.fn(() => Promise.resolve());
    unmuteConversation = jest.fn(() => Promise.resolve());

    modules = {
      conversations: {
        actions: {
          muteConversation,
          unmuteConversation,
        },
      },
    };

    getters = {
      getSelectedChat: () => currentChat,
    };

    store = new Vuex.Store({
      state,
      modules,
      getters,
    });

    moreActions = mount(MoreActions, { store, localVue, i18n: i18nConfig });
  });

  describe('muting discussion', () => {
    it('triggers "muteConversation"', async () => {
      await moreActions.find('button:first-child').trigger('click');

      expect(muteConversation).toBeCalledWith(
        expect.any(Object),
        currentChat.id,
        undefined
      );
    });

    it('shows alert', async () => {
      await moreActions.find('button:first-child').trigger('click');

      expect(window.bus.$emit).toBeCalledWith(
        'newToastMessage',
        'This conversation is muted for 6 hours'
      );
    });
  });

  describe('unmuting discussion', () => {
    beforeEach(() => {
      currentChat.muted = true;
    });

    it('triggers "unmuteConversation"', async () => {
      await moreActions.find('button:first-child').trigger('click');

      expect(unmuteConversation).toBeCalledWith(
        expect.any(Object),
        currentChat.id,
        undefined
      );
    });

    it('shows alert', async () => {
      await moreActions.find('button:first-child').trigger('click');

      expect(window.bus.$emit).toBeCalledWith(
        'newToastMessage',
        'This conversation is unmuted'
      );
    });
  });
});
