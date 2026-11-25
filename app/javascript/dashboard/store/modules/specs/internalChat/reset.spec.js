import { createStore } from 'vuex';
import internalChat from '../../internalChat';

describe('internalChat/reset', () => {
  it('drops channels, messages, drafts and search results', async () => {
    const store = createStore({ modules: { internalChat } });
    store.commit('internalChat/SET_CHANNELS', [{ id: 1, name: 'general' }]);
    store.commit('internalChat/SET_ACTIVE_CHANNEL', 1);
    store.state.internalChat.messages.records = {
      1: [{ id: 9, content: 'hi' }],
    };
    store.state.internalChat.drafts.records = { 1: { content: 'draft' } };
    store.state.internalChat.search.messages = [{ id: 9 }];

    await store.dispatch('internalChat/reset');

    expect(store.getters['internalChat/getChannels']).toEqual([]);
    expect(store.state.internalChat.activeChannelId).toBeNull();
    expect(store.state.internalChat.messages.records).toEqual({});
    expect(store.state.internalChat.drafts.records).toEqual({});
    expect(store.state.internalChat.search.messages).toEqual([]);
  });
});
