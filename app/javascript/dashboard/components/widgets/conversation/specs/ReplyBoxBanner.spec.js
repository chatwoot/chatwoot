import { flushPromises, shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import Banner from 'dashboard/components/ui/Banner.vue';
import ReplyBoxBanner from '../ReplyBoxBanner.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
}));

describe('ReplyBoxBanner', () => {
  it('offers takeover and assigns the current agent when Captain owns the conversation', async () => {
    const toggleStatus = vi.fn();
    const setCurrentChatAssignee = vi.fn();
    const assignAgent = vi.fn();
    const assistant = { id: 3, name: 'Captain' };
    const currentUser = {
      id: 7,
      name: 'Agent',
      avatar_url: 'agent.png',
    };
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

    expect(toggleStatus).toHaveBeenCalledWith(expect.anything(), {
      conversationId: 1,
      status: 'open',
    });
    expect(assignAgent).toHaveBeenCalledWith(expect.anything(), {
      conversationId: 1,
      agentId: currentUser.id,
    });
  });
});
