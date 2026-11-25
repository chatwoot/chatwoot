import { flushPromises, shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import Banner from 'dashboard/components/ui/Banner.vue';
import ReplyBoxBanner from '../ReplyBoxBanner.vue';

vi.mock('vue-i18n', () => ({
  useI18n: () => ({ t: key => key }),
}));

vi.mock('dashboard/composables', () => ({
  useAlert: vi.fn(),
  useAssignmentError: vi.fn(),
}));

describe('ReplyBoxBanner', () => {
  const currentUser = { id: 7 };

  // The fork routes the claim through the `assignAgent` store action, which owns the optimistic
  // write and its rollback; the status only changes once that claim has gone through.
  it.each([false, true])(
    'only updates takeover after assignment succeeds (fails: %s)',
    async requestFails => {
      const assignAgent = vi.fn();
      const changeStatus = vi.fn();
      if (requestFails) {
        assignAgent.mockRejectedValue(new Error('Failed'));
      } else {
        assignAgent.mockResolvedValue();
      }
      const store = createStore({
        state: {
          chat: {
            id: 1,
            status: 'pending',
            meta: {
              assignee: { id: 3, name: 'Captain' },
              assignee_type: 'Captain::Assistant',
            },
          },
        },
        getters: {
          getSelectedChat: state => state.chat,
          getCurrentUser: () => currentUser,
        },
        actions: { assignAgent },
        mutations: { CHANGE_CONVERSATION_STATUS: changeStatus },
      });
      const wrapper = shallowMount(ReplyBoxBanner, {
        global: {
          plugins: [store],
          mocks: {
            $t: key => key,
          },
        },
      });

      const banner = wrapper.findComponent(Banner);
      expect(banner.exists()).toBe(true);
      banner.vm.$emit('primaryAction');
      await flushPromises();

      expect(assignAgent).toHaveBeenCalledWith(expect.anything(), {
        conversationId: 1,
        assignee: expect.objectContaining({ id: currentUser.id }),
        assigneeType: 'User',
      });
      if (requestFails) {
        expect(changeStatus).not.toHaveBeenCalled();
        expect(wrapper.findComponent(Banner).exists()).toBe(true);
        return;
      }
      expect(changeStatus).toHaveBeenCalledWith(expect.anything(), {
        conversationId: 1,
        status: 'open',
        snoozedUntil: null,
      });
    }
  );
});
