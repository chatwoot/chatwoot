import { flushPromises, shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import Banner from 'dashboard/components/ui/Banner.vue';
import ReplyBoxBanner from '../ReplyBoxBanner.vue';
import ConversationApi from 'dashboard/api/inbox/conversation';
import { useAlert } from 'dashboard/composables';

vi.mock('dashboard/api/inbox/conversation', () => ({
  default: { assignAgent: vi.fn() },
}));

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

describe('ReplyBoxBanner', () => {
  it.each([false, true])(
    'only completes takeover after a successful assignment (failure: %s)',
    async failure => {
      const toggleStatus = vi.fn();
      const setCurrentChatAssignee = vi.fn();
      const assignAgent = vi.fn();
      const assistant = { id: 3, name: 'Captain' };
      const currentUser = {
        id: 7,
        name: 'Agent',
        avatar_url: 'agent.png',
      };
      useAlert.mockClear();
      ConversationApi.assignAgent.mockReset();
      if (failure) {
        ConversationApi.assignAgent.mockRejectedValue(
          new Error('Assignment failed')
        );
      } else {
        ConversationApi.assignAgent.mockResolvedValue({ data: currentUser });
      }
      const store = createStore({
        state: {
          chat: {
            id: 1,
            status: 'pending',
            meta: {
              assignee: assistant,
              assignee_type: 'Captain::Assistant',
            },
          },
        },
        getters: {
          getSelectedChat: state => state.chat,
          getCurrentUser: () => currentUser,
        },
        actions: {
          toggleStatus,
          setCurrentChatAssignee,
          assignAgent,
        },
      });
      const wrapper = shallowMount(ReplyBoxBanner, {
        global: {
          plugins: [store],
          mocks: {
            $t: (key, params) =>
              params?.assigneeName ? `${key}: ${params.assigneeName}` : key,
          },
        },
      });

      const banner = wrapper.findComponent(Banner);
      expect(banner.exists()).toBe(true);
      expect(banner.props('bannerMessage')).toContain(assistant.name);

      banner.vm.$emit('primaryAction');
      await flushPromises();

      expect(ConversationApi.assignAgent).toHaveBeenCalledWith({
        conversationId: 1,
        agentId: currentUser.id,
        assigneeType: 'User',
      });
      if (failure) {
        expect(setCurrentChatAssignee).not.toHaveBeenCalled();
        expect(toggleStatus).not.toHaveBeenCalled();
        expect(useAlert).toHaveBeenCalledWith('CONVERSATION.BOT_HANDOFF_ERROR');
        return;
      }
      expect(toggleStatus).toHaveBeenCalledWith(expect.anything(), {
        conversationId: 1,
        status: 'open',
      });
      expect(setCurrentChatAssignee).toHaveBeenCalledWith(expect.anything(), {
        conversationId: 1,
        assignee: currentUser,
        assigneeType: 'User',
      });
    }
  );
});
