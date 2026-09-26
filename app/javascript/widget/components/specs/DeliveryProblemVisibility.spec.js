import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ConversationWrap from '../ConversationWrap.vue';

/**
 * .
 *
 * Setting a failure flag in the store is not a fix on its own. If nothing
 * renders it, the failure is still invisible to the customer, which is the
 * defect rather than a remedy for it. These tests fail if the flag stops being
 * rendered, so the visible surface cannot be quietly removed later.
 */
const buildStore = ({ isSyncFailed, syncSpy = vi.fn() }) =>
  createStore({
    modules: {
      conversation: {
        namespaced: true,
        getters: {
          getEarliestMessage: () => ({}),
          getLastMessage: () => ({}),
          getAllMessagesLoaded: () => true,
          getIsFetchingList: () => false,
          getConversationSize: () => 0,
          getIsAgentTyping: () => false,
          getIsSyncFailed: () => isSyncFailed,
        },
        actions: { syncLatestMessages: syncSpy },
      },
      conversationAttributes: {
        namespaced: true,
        getters: { getConversationParams: () => ({ status: 'open' }) },
      },
    },
  });

const mountWrap = (isSyncFailed, syncSpy = vi.fn()) =>
  shallowMount(ConversationWrap, {
    global: {
      plugins: [buildStore({ isSyncFailed, syncSpy })],
      mocks: { $t: key => key },
    },
    props: { groupedMessages: [] },
  });

describe('delivery problem visibility', () => {
  it('says nothing when the sync is healthy', () => {
    const wrapper = mountWrap(false);
    expect(wrapper.find('.sync-failed').exists()).toBe(false);
  });

  it('tells the customer when recovering messages has failed', () => {
    const wrapper = mountWrap(true);
    const banner = wrapper.find('.sync-failed');
    expect(banner.exists()).toBe(true);
    expect(banner.text()).toContain('DELIVERY_PROBLEM.SYNC_FAILED');
  });

  it('offers a retry rather than only a message', () => {
    const wrapper = mountWrap(true);
    expect(wrapper.find('.sync-failed--retry').exists()).toBe(true);
  });

  /**
   * A button that exists is not a button that works. An earlier revision of
   * this change declared retrySync in a second `methods` block, so the object
   * literal's later `methods` key silently discarded it: the banner rendered,
   * the button rendered, every assertion above passed, and clicking it did
   * nothing at all. Assert the action fires, not that the markup is present.
   */
  it('actually dispatches the sync when the retry is clicked', async () => {
    const syncSpy = vi.fn();
    const wrapper = mountWrap(true, syncSpy);

    expect(typeof wrapper.vm.retrySync).toBe('function');
    await wrapper.find('.sync-failed--retry').trigger('click');

    expect(syncSpy).toHaveBeenCalledTimes(1);
  });

  it('announces the failure to assistive technology', () => {
    const wrapper = mountWrap(true);
    expect(wrapper.find('.sync-failed').attributes('role')).toBe('status');
  });
});
