import { describe, it, beforeEach, afterEach, expect, vi } from 'vitest';
import { mount } from '@vue/test-utils';
import { createStore } from 'vuex';
import conversation from 'widget/store/modules/conversation';
import ConversationWrap from '../ConversationWrap.vue';
import ActionCableConnector from 'widget/helpers/actionCable';
import { MESSAGE_TYPE } from 'shared/constants/messages';

vi.mock('@rails/actioncable', () => ({
  createConsumer: () => ({
    subscriptions: { create: () => ({ updatePresence: vi.fn() }) },
    disconnect: vi.fn(),
  }),
}));

// The bubble a pending conversation shows on the visitor's last message is an implicit typing_on: it
// follows the same 30 seconds a real typing_on gets, a real typing_on renews it and a real typing_off
// clears it (fazer-ai/chatwoot#744).
const CONVERSATION_ID = 7;
const NOW = new Date('2026-10-05T12:00:00Z').getTime();

const buildStore = status =>
  createStore({
    modules: {
      conversation: {
        ...conversation,
        state: () => JSON.parse(JSON.stringify(conversation.state)),
      },
      conversationAttributes: {
        namespaced: true,
        state: () => ({ id: CONVERSATION_ID, status }),
        getters: { getConversationParams: $state => $state },
      },
      appConfig: {
        namespaced: true,
        getters: { darkMode: () => 'light' },
      },
    },
  });

const message = (id, messageType, createdAt = Date.now() / 1000) => ({
  id,
  content: `message ${id}`,
  message_type: messageType,
  conversation_id: CONVERSATION_ID,
  created_at: createdAt,
  status: 'sent',
});

describe('ConversationWrap typing bubble', () => {
  let store;
  let connector;
  let wrapper;

  const mountWith = status => {
    store = buildStore(status);
    connector = new ActionCableConnector({ $store: store }, 'token');
    wrapper = mount(ConversationWrap, {
      global: {
        plugins: [store],
        stubs: { ChatMessage: true, DateSeparator: true, Spinner: true },
      },
    });
  };

  const bubbleShown = () =>
    wrapper.findComponent({ name: 'AgentTypingBubble' }).exists();

  const advance = async ms => {
    vi.advanceTimersByTime(ms);
    await wrapper.vm.$nextTick();
  };

  const visitorSends = async id => {
    connector.onMessageCreated(message(id, MESSAGE_TYPE.INCOMING));
    await wrapper.vm.$nextTick();
  };

  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(NOW);
  });

  afterEach(() => {
    wrapper?.unmount();
    vi.useRealTimers();
  });

  it('shows the bubble on a pending conversation for 30 seconds after the visitor message', async () => {
    mountWith('pending');
    await visitorSends(1);
    expect(bubbleShown()).toBe(true);

    await advance(29_000);
    expect(bubbleShown()).toBe(true);

    await advance(1_500);
    expect(bubbleShown()).toBe(false);
    expect(
      store.getters['conversationAttributes/getConversationParams'].status
    ).toBe('pending');
  });

  it('keeps the bubble while the agent side renews it with typing_on', async () => {
    mountWith('pending');
    await visitorSends(1);

    await advance(20_000);
    connector.onTypingOn({ conversation: { id: CONVERSATION_ID } });
    await advance(25_000);
    expect(bubbleShown()).toBe(true);

    await advance(6_000);
    expect(bubbleShown()).toBe(false);
  });

  it('clears the bubble at once on a typing_off from the agent side', async () => {
    mountWith('pending');
    await visitorSends(1);

    await advance(5_000);
    connector.onTypingOff({ conversation: { id: CONVERSATION_ID } });
    await wrapper.vm.$nextTick();
    expect(bubbleShown()).toBe(false);
  });

  it.each([
    [
      'a private note',
      { conversation: { id: CONVERSATION_ID }, is_private: true },
    ],
    ['another conversation', { conversation: { id: CONVERSATION_ID + 1 } }],
  ])('keeps the bubble on a typing_off from %s', async (_, data) => {
    mountWith('pending');
    await visitorSends(1);

    await advance(5_000);
    connector.onTypingOff(data);
    await wrapper.vm.$nextTick();
    expect(bubbleShown()).toBe(true);
  });

  it('counts a message loaded after a typing_off from its own stored time', async () => {
    mountWith('pending');
    await visitorSends(1);
    connector.onTypingOff({ conversation: { id: CONVERSATION_ID } });
    await wrapper.vm.$nextTick();

    store.commit('conversation/clearConversations');
    store.commit('conversation/setMessagesInConversation', [
      message(2, MESSAGE_TYPE.INCOMING, (NOW - 5_000) / 1000),
    ]);
    await wrapper.vm.$nextTick();
    expect(bubbleShown()).toBe(true);
  });

  it('counts a message recovered after reconnecting from its own stored time', async () => {
    mountWith('pending');
    await visitorSends(1);
    await advance(31_000);

    // syncLatestMessages writes the recovered messages into the map directly.
    store.state.conversation.conversations[2] = message(
      2,
      MESSAGE_TYPE.INCOMING,
      (Date.now() - 5_000) / 1000
    );
    await wrapper.vm.$nextTick();
    expect(bubbleShown()).toBe(true);
  });

  it('does not let an earlier typing_on expiring cut the window of a newer visitor message', async () => {
    mountWith('pending');
    connector.onTypingOn({ conversation: { id: CONVERSATION_ID } });
    await advance(20_000);
    await visitorSends(1);

    await advance(15_000);
    expect(bubbleShown()).toBe(true);
  });

  it('opens a new window for a visitor message sent after the previous one expired', async () => {
    mountWith('pending');
    await visitorSends(1);
    await advance(31_000);
    expect(bubbleShown()).toBe(false);

    await visitorSends(2);
    expect(bubbleShown()).toBe(true);
    await advance(29_000);
    expect(bubbleShown()).toBe(true);
  });

  it('counts the window of a message seen arriving from the visitor clock, not from its stored time', async () => {
    mountWith('pending');
    connector.onMessageCreated(
      message(1, MESSAGE_TYPE.INCOMING, (NOW - 60_000) / 1000)
    );
    await wrapper.vm.$nextTick();
    expect(bubbleShown()).toBe(true);
  });

  it('does not reopen the window when a visitor message already shown is updated', async () => {
    mountWith('pending');
    await visitorSends(1);
    await advance(20_000);
    connector.onMessageUpdated(message(1, MESSAGE_TYPE.INCOMING, NOW / 1000));

    await advance(11_000);
    expect(bubbleShown()).toBe(false);
  });

  it('after a reload, shows the bubble only until 30 seconds past the stored message time', async () => {
    mountWith('pending');
    store.commit('conversation/setMessagesInConversation', [
      message(1, MESSAGE_TYPE.INCOMING, (NOW - 10_000) / 1000),
    ]);
    await wrapper.vm.$nextTick();
    expect(bubbleShown()).toBe(true);

    await advance(19_000);
    expect(bubbleShown()).toBe(true);

    await advance(1_500);
    expect(bubbleShown()).toBe(false);
  });

  it('after a reload, shows no bubble when the visitor message is older than 30 seconds', async () => {
    mountWith('pending');
    store.commit('conversation/setMessagesInConversation', [
      message(1, MESSAGE_TYPE.INCOMING, (NOW - 60_000) / 1000),
    ]);
    await wrapper.vm.$nextTick();
    expect(bubbleShown()).toBe(false);
  });

  it('shows no implicit bubble when the conversation is not pending', async () => {
    mountWith('open');
    await visitorSends(1);
    expect(bubbleShown()).toBe(false);
  });

  it('shows no implicit bubble when the last message is outgoing', async () => {
    mountWith('pending');
    await visitorSends(1);
    connector.onMessageCreated(message(2, MESSAGE_TYPE.OUTGOING));
    await wrapper.vm.$nextTick();
    expect(bubbleShown()).toBe(false);
  });
});
