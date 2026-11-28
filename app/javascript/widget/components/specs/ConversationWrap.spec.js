import { shallowMount } from '@vue/test-utils';
import { createStore } from 'vuex';
import ConversationWrap from '../ConversationWrap.vue';

const store = createStore({
  modules: {
    appConfig: {
      namespaced: true,
      getters: { darkMode: () => 'light' },
    },
    conversation: {
      namespaced: true,
      getters: {
        getEarliestMessage: () => ({}),
        getLastMessage: () => ({}),
        getAllMessagesLoaded: () => true,
        getIsFetchingList: () => false,
        getConversationSize: () => 0,
        getIsAgentTyping: () => false,
      },
      actions: { fetchOldConversations: () => {} },
    },
    conversationAttributes: {
      namespaced: true,
      getters: { getConversationParams: () => ({}) },
    },
  },
});

describe('ConversationWrap', () => {
  let wrapper;
  let container;

  beforeEach(() => {
    wrapper = shallowMount(ConversationWrap, {
      global: { plugins: [store] },
    });
    container = wrapper.element;
    Object.defineProperty(container, 'scrollHeight', { value: 1000 });
    Object.defineProperty(container, 'clientHeight', {
      configurable: true,
      value: 400,
    });
    Object.defineProperty(container, 'scrollTop', {
      writable: true,
      value: 0,
    });
  });

  afterEach(() => {
    wrapper.unmount();
  });

  it('keeps the latest message in view when the widget shrinks', async () => {
    container.scrollTop = 600;
    await wrapper.trigger('scroll');

    Object.defineProperty(container, 'clientHeight', { value: 200 });
    window.dispatchEvent(new Event('resize'));

    expect(container.scrollTop).toBe(1000);
  });

  it('keeps the scroll position when the visitor scrolled up', async () => {
    container.scrollTop = 100;
    await wrapper.trigger('scroll');

    window.dispatchEvent(new Event('resize'));

    expect(container.scrollTop).toBe(100);
  });
});
