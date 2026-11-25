import { describe, it, expect, beforeEach, vi } from 'vitest';
import { defineComponent } from 'vue';
import { flushPromises, mount } from '@vue/test-utils';
import ConversationHistorySync from '../ConversationHistorySync.vue';

const mockDispatch = vi.fn();
vi.mock('vuex', () => ({ useStore: () => ({ dispatch: mockDispatch }) }));

vi.mock('vue-i18n', async () => {
  const actual = await vi.importActual('vue-i18n');
  return { ...actual, useI18n: () => ({ t: key => key }) };
});

const mockAlert = vi.fn();
vi.mock('dashboard/composables', () => ({
  useAlert: (...args) => mockAlert(...args),
}));

const mountControl = (props = {}) =>
  mount(ConversationHistorySync, {
    props: { conversationId: 7, ...props },
    global: {
      stubs: {
        NextButton: defineComponent({
          name: 'NextButton',
          template:
            '<button class="NextButton-stub" @click="$emit(\'click\')" />',
        }),
      },
    },
  });

const button = wrapper => wrapper.find('.NextButton-stub');

describe('ConversationHistorySync', () => {
  beforeEach(() => vi.clearAllMocks());

  it('asks the provider for the page before this thread', async () => {
    mockDispatch.mockResolvedValue({});
    const wrapper = mountControl();

    await button(wrapper).trigger('click');
    await flushPromises();

    expect(mockDispatch).toHaveBeenCalledWith('syncHistory', 7);
  });

  // The phone answers on the webhook minutes later, or never, so the press can only
  // report that the request went out, and where to look: each message is filed in the
  // conversation from its own date.
  it('reports that the phone was asked, and that the messages go by date', async () => {
    mockDispatch.mockResolvedValue({});
    const wrapper = mountControl();

    await button(wrapper).trigger('click');
    await flushPromises();

    expect(mockAlert).toHaveBeenCalledWith(
      'CONVERSATION.HISTORY_SYNC.REQUESTED_BY_DATE'
    );
  });

  it('says they appear here on an inbox locked to one conversation', async () => {
    mockDispatch.mockResolvedValue({});
    const wrapper = mountControl({ singleConversation: true });

    await button(wrapper).trigger('click');
    await flushPromises();

    expect(mockAlert).toHaveBeenCalledWith(
      'CONVERSATION.HISTORY_SYNC.REQUESTED'
    );
  });

  // WhatsApp only says a chat is finished on the answer to a request, so this state is
  // reached by asking, never offered before the first press.
  it('stops offering once the phone said there is nothing older', () => {
    const wrapper = mountControl({ exhausted: true });

    expect(button(wrapper).exists()).toBe(false);
    expect(wrapper.text()).toContain('CONVERSATION.HISTORY_SYNC.EXHAUSTED');
  });

  it('offers the request while nothing has said the chat is finished', () => {
    const wrapper = mountControl();

    expect(button(wrapper).exists()).toBe(true);
    expect(wrapper.text()).not.toContain('CONVERSATION.HISTORY_SYNC.EXHAUSTED');
  });

  it('reports a request the server refused', async () => {
    mockDispatch.mockRejectedValue(new Error('nope'));
    const wrapper = mountControl();

    await button(wrapper).trigger('click');
    await flushPromises();

    expect(mockAlert).toHaveBeenCalledWith('CONVERSATION.HISTORY_SYNC.ERROR');
  });
});
