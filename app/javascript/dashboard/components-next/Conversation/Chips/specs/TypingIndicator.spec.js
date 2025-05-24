import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import { nextTick } from 'vue';
import TypingIndicator from '../TypingIndicator.vue';

const createComponent = ({ typingUsers = [] } = {}) => {
  const store = createStore({
    modules: {
      conversations: {
        getters: {
          getSelectedChat: () => ({ id: 1 }),
        },
      },
      conversationTypingStatus: {
        namespaced: true,
        getters: {
          getUserList: () => chatId => {
            // Ensure we're returning the typing users for the correct chat
            if (chatId === 1) {
              return typingUsers;
            }
            return [];
          },
        },
      },
    },
  });

  return mount(TypingIndicator, {
    global: {
      plugins: [store],
    },
  });
};

describe('TypingIndicator', () => {
  it('should not be visible when no one is typing', () => {
    const wrapper = createComponent();
    expect(wrapper.isVisible()).toBe(false);
  });

  it('should display the correct message when one user is typing', async () => {
    const wrapper = createComponent({
      typingUsers: [{ id: 1, name: 'John' }],
    });
    await nextTick();
    expect(wrapper.isVisible()).toBe(true);
    expect(wrapper.text()).toContain('John is typing');
  });

  it('should display the correct message when two users are typing', async () => {
    const wrapper = createComponent({
      typingUsers: [
        { id: 1, name: 'John' },
        { id: 2, name: 'Jane' },
      ],
    });
    await nextTick();
    expect(wrapper.isVisible()).toBe(true);
    expect(wrapper.text()).toContain('John and Jane are typing');
  });

  it('should display the correct message when more than two users are typing', async () => {
    const wrapper = createComponent({
      typingUsers: [
        { id: 1, name: 'John' },
        { id: 2, name: 'Jane' },
        { id: 3, name: 'Bob' },
      ],
    });
    await nextTick();
    expect(wrapper.isVisible()).toBe(true);
    expect(wrapper.text()).toContain('John and 2 others are typing');
  });
});
