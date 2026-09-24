import { getConversationsAPI } from '../../api/conversation';

const state = {
  records: [],
  page: 0,
  hasNextPage: false,
  unreadCount: 0,
  uiFlags: {
    isFetching: false,
  },
};

const findRecord = ($state, id) =>
  $state.records.find(record => record.id === id);

export const getters = {
  getRecords: $state => $state.records,
  getLatestConversation: $state => $state.records[0],
  getHasNextPage: $state => $state.hasNextPage,
  getIsFetching: $state => $state.uiFlags.isFetching,
  // The conversation on screen reports its own unread state from the thread.
  getUnreadCount: ($state, _getters, rootState) => {
    const active = findRecord($state, rootState.conversationAttributes.id);
    return $state.unreadCount - (active?.unread_count > 0 ? 1 : 0);
  },
};

export const actions = {
  fetch: async ({ commit }, { page = 1 } = {}) => {
    commit('setFetching', true);
    try {
      const {
        data: { payload, meta },
      } = await getConversationsAPI({ page });
      commit('setRecords', {
        payload,
        page,
        hasNextPage: meta.has_next_page,
        unreadCount: meta.unread_count,
      });
    } catch (error) {
      // Ignore error
    } finally {
      commit('setFetching', false);
    }
  },

  fetchMore: ({ state: listState, dispatch }) => {
    if (!listState.hasNextPage || listState.uiFlags.isFetching) return;
    dispatch('fetch', { page: listState.page + 1 });
  },

  // Records are newest-activity first, so the first match is the most recent one.
  load: async ({ state: listState, dispatch }) => {
    await dispatch('startNew');
    await dispatch('fetch');
    const conversation =
      listState.records.find(record => record.unread_count > 0) ||
      listState.records.find(record => record.status !== 'resolved') ||
      listState.records[0];
    if (conversation) await dispatch('open', conversation.id);
  },

  open: async ({ state: listState, commit, dispatch, rootState }, id) => {
    const previousId = rootState.conversationAttributes.id;
    if (previousId === id) return;
    if (previousId) {
      dispatch('conversation/clearConversations', {}, { root: true });
    }
    if (!findRecord(listState, id)) {
      commit(
        'conversationAttributes/SET_CONVERSATION_ATTRIBUTES',
        { id },
        { root: true }
      );
      await dispatch('fetch');
    }
    const record = findRecord(listState, id) || { id };
    commit('conversationAttributes/SET_CONVERSATION_ATTRIBUTES', record, {
      root: true,
    });
    commit('conversation/setMetaUserLastSeenAt', record.contact_last_seen_at, {
      root: true,
    });
    commit('markRead', id);
    await dispatch('conversation/fetchOldConversations', {}, { root: true });
  },

  startNew: async ({ dispatch }) => {
    await dispatch(
      'conversationAttributes/clearConversationAttributes',
      {},
      { root: true }
    );
    await dispatch('conversation/clearConversations', {}, { root: true });
  },
};

export const mutations = {
  setRecords($state, { payload, page, hasNextPage, unreadCount }) {
    const known = new Set($state.records.map(record => record.id));
    $state.records =
      page === 1
        ? payload
        : [...$state.records, ...payload.filter(r => !known.has(r.id))];
    $state.page = page;
    $state.hasNextPage = hasNextPage;
    $state.unreadCount = unreadCount;
  },
  setFetching($state, isFetching) {
    $state.uiFlags.isFetching = isFetching;
  },
  markRead($state, id) {
    const record = findRecord($state, id);
    if (!record?.unread_count) return;
    record.unread_count = 0;
    $state.unreadCount -= 1;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
