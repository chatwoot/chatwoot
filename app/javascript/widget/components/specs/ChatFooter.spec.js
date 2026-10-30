import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { useRouter } from 'vue-router';

import ChatFooter from '../ChatFooter.vue';
import { IFrameHelper } from 'widget/helpers/utils';
import { CHATWOOT_ON_START_CONVERSATION } from 'widget/constants/sdkEvents';

vi.mock('vue-router', () => ({
  useRouter: vi.fn(),
}));

vi.mock('widget/helpers/utils', () => ({
  IFrameHelper: {
    sendMessage: vi.fn(),
  },
}));

const createWrapper = ({ conversationAttributes = {} } = {}) => {
  const replace = vi.fn();
  const clearConversations = vi.fn();
  const clearConversationAttributes = vi.fn();

  vi.mocked(useRouter).mockReturnValue({ replace });

  const store = createStore({
    modules: {
      conversation: {
        namespaced: true,
        getters: {
          getConversationSize: () => 1,
        },
        actions: {
          sendMessage: vi.fn(),
          sendAttachment: vi.fn(),
          clearConversations,
        },
      },
      conversationAttributes: {
        namespaced: true,
        getters: {
          getConversationParams: () => ({
            id: 1,
            status: 'resolved',
            ...conversationAttributes,
          }),
        },
        actions: {
          getAttributes: vi.fn(),
          clearConversationAttributes,
        },
      },
      appConfig: {
        namespaced: true,
        getters: {
          getWidgetColor: () => '#1f93ff',
          isWidgetStyleFlat: () => false,
        },
      },
      contacts: {
        namespaced: true,
        getters: {
          getCurrentUser: () => ({ has_email: false }),
        },
      },
    },
  });

  const wrapper = shallowMount(ChatFooter, {
    global: {
      plugins: [store],
      mocks: {
        $t: key => key,
      },
    },
  });

  return {
    clearConversationAttributes,
    clearConversations,
    replace,
    wrapper,
  };
};

describe('ChatFooter', () => {
  beforeEach(() => {
    window.chatwootWebChannel = {
      allowMessagesAfterResolved: false,
    };
    vi.clearAllMocks();
  });

  it('clears resolved conversation state before starting a new conversation', () => {
    const {
      clearConversationAttributes,
      clearConversations,
      replace,
      wrapper,
    } = createWrapper();

    wrapper.vm.startNewConversation();

    expect(clearConversations).toHaveBeenCalled();
    expect(clearConversationAttributes).toHaveBeenCalled();
    expect(replace).toHaveBeenCalledWith({ name: 'prechat-form' });
    expect(IFrameHelper.sendMessage).toHaveBeenCalledWith({
      event: 'onEvent',
      eventIdentifier: CHATWOOT_ON_START_CONVERSATION,
      data: { hasConversation: true },
    });
  });
});
