---
name: vuex-store
description: Manage application state with Vuex in Chatwoot dashboard. Use this skill when working with global state, creating store modules, or handling data flow between components.
metadata:
  author: chatwoot
  version: "1.0"
---

# Vuex Store Management

## Overview

Chatwoot dashboard uses Vuex for state management. The store is organized into modules for different domain areas.

## Structure

```
app/javascript/dashboard/store/
├── index.js                    # Store initialization
├── modules/
│   ├── accounts.js            # Account management
│   ├── agent.js               # Agent/user state
│   ├── auth.js                # Authentication
│   ├── contacts/              # Contacts module
│   ├── conversations/         # Conversations module
│   ├── inboxes.js             # Inbox management
│   ├── labels.js              # Labels/tags
│   ├── notifications.js       # Notifications
│   └── ...
```

## Store Module Pattern

### Complete Module Example

```javascript
// app/javascript/dashboard/store/modules/labels.js
import LabelsAPI from '../../api/labels';
import types from '../mutation-types';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
  },
};

const getters = {
  getLabels: (state) => state.records,
  getLabelById: (state) => (id) => {
    return state.records.find((label) => label.id === id);
  },
  getUIFlags: (state) => state.uiFlags,
};

const mutations = {
  [types.SET_LABELS](state, labels) {
    state.records = labels;
  },
  [types.ADD_LABEL](state, label) {
    state.records.push(label);
  },
  [types.UPDATE_LABEL](state, updatedLabel) {
    const index = state.records.findIndex((l) => l.id === updatedLabel.id);
    if (index !== -1) {
      state.records.splice(index, 1, updatedLabel);
    }
  },
  [types.DELETE_LABEL](state, labelId) {
    state.records = state.records.filter((l) => l.id !== labelId);
  },
  [types.SET_LABEL_UI_FLAG](state, { key, value }) {
    state.uiFlags[key] = value;
  },
};

const actions = {
  async fetch({ commit }) {
    commit(types.SET_LABEL_UI_FLAG, { key: 'isFetching', value: true });
    try {
      const { data } = await LabelsAPI.get();
      commit(types.SET_LABELS, data);
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_LABEL_UI_FLAG, { key: 'isFetching', value: false });
    }
  },

  async create({ commit }, labelData) {
    commit(types.SET_LABEL_UI_FLAG, { key: 'isCreating', value: true });
    try {
      const { data } = await LabelsAPI.create(labelData);
      commit(types.ADD_LABEL, data);
      return data;
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_LABEL_UI_FLAG, { key: 'isCreating', value: false });
    }
  },

  async update({ commit }, { id, ...updateData }) {
    try {
      const { data } = await LabelsAPI.update(id, updateData);
      commit(types.UPDATE_LABEL, data);
      return data;
    } catch (error) {
      throw error;
    }
  },

  async delete({ commit }, labelId) {
    try {
      await LabelsAPI.delete(labelId);
      commit(types.DELETE_LABEL, labelId);
    } catch (error) {
      throw error;
    }
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};
```

### Mutation Types

```javascript
// app/javascript/dashboard/store/mutation-types.js
export default {
  // Labels
  SET_LABELS: 'SET_LABELS',
  ADD_LABEL: 'ADD_LABEL',
  UPDATE_LABEL: 'UPDATE_LABEL',
  DELETE_LABEL: 'DELETE_LABEL',
  SET_LABEL_UI_FLAG: 'SET_LABEL_UI_FLAG',

  // Conversations
  SET_CONVERSATIONS: 'SET_CONVERSATIONS',
  ADD_CONVERSATION: 'ADD_CONVERSATION',
  UPDATE_CONVERSATION: 'UPDATE_CONVERSATION',
  SET_CURRENT_CONVERSATION: 'SET_CURRENT_CONVERSATION',
  SET_CONVERSATION_UI_FLAG: 'SET_CONVERSATION_UI_FLAG',

  // Messages
  SET_MESSAGES: 'SET_MESSAGES',
  ADD_MESSAGE: 'ADD_MESSAGE',
  UPDATE_MESSAGE: 'UPDATE_MESSAGE',

  // Contacts
  SET_CONTACTS: 'SET_CONTACTS',
  SET_CONTACT: 'SET_CONTACT',
  UPDATE_CONTACT: 'UPDATE_CONTACT',
};
```

## Using Store in Components

### With Composition API

```vue
<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'vuex';

const store = useStore();

// State
const labels = computed(() => store.getters['labels/getLabels']);
const isFetching = computed(() => store.getters['labels/getUIFlags'].isFetching);

// Actions
const fetchLabels = () => store.dispatch('labels/fetch');
const createLabel = (data) => store.dispatch('labels/create', data);
const deleteLabel = (id) => store.dispatch('labels/delete', id);

onMounted(() => {
  if (labels.value.length === 0) {
    fetchLabels();
  }
});
</script>

<template>
  <div>
    <div v-if="isFetching">Loading...</div>
    <ul v-else>
      <li v-for="label in labels" :key="label.id">
        {{ label.title }}
        <button @click="deleteLabel(label.id)">Delete</button>
      </li>
    </ul>
  </div>
</template>
```

### Using mapGetters/mapActions (Options API)

```vue
<script>
import { mapGetters, mapActions } from 'vuex';

export default {
  computed: {
    ...mapGetters('labels', ['getLabels', 'getUIFlags']),
    ...mapGetters('conversations', ['getCurrentConversation']),
  },
  methods: {
    ...mapActions('labels', ['fetch', 'create', 'delete']),
    ...mapActions('conversations', ['updateConversation']),
  },
  mounted() {
    this.fetch();
  },
};
</script>
```

## Complex Module: Conversations

```javascript
// app/javascript/dashboard/store/modules/conversations/index.js
import getters from './getters';
import mutations from './mutations';
import actions from './actions';

const state = {
  allConversations: [],
  currentConversationId: null,
  conversationFilters: {
    status: 'open',
    assigneeType: 'me',
    inboxId: null,
  },
  uiFlags: {
    isFetching: false,
    isFetchingMore: false,
    isUpdating: false,
  },
  meta: {
    currentPage: 1,
    totalCount: 0,
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};

// getters.js
export default {
  getAllConversations: (state) => state.allConversations,
  
  getCurrentConversation: (state) => {
    return state.allConversations.find(
      (c) => c.id === state.currentConversationId
    );
  },
  
  getConversationsByStatus: (state) => (status) => {
    return state.allConversations.filter((c) => c.status === status);
  },
  
  getOpenConversationsCount: (state) => {
    return state.allConversations.filter((c) => c.status === 'open').length;
  },
  
  getFilteredConversations: (state, getters, rootState, rootGetters) => {
    let conversations = [...state.allConversations];
    const { status, assigneeType, inboxId } = state.conversationFilters;

    if (status) {
      conversations = conversations.filter((c) => c.status === status);
    }

    if (inboxId) {
      conversations = conversations.filter((c) => c.inbox_id === inboxId);
    }

    if (assigneeType === 'me') {
      const currentUserId = rootGetters['auth/getCurrentUserId'];
      conversations = conversations.filter(
        (c) => c.meta?.assignee?.id === currentUserId
      );
    }

    return conversations;
  },
};

// mutations.js
import types from '../../mutation-types';

export default {
  [types.SET_CONVERSATIONS](state, conversations) {
    state.allConversations = conversations;
  },

  [types.ADD_CONVERSATION](state, conversation) {
    const exists = state.allConversations.some((c) => c.id === conversation.id);
    if (!exists) {
      state.allConversations.unshift(conversation);
    }
  },

  [types.UPDATE_CONVERSATION](state, conversation) {
    const index = state.allConversations.findIndex(
      (c) => c.id === conversation.id
    );
    if (index !== -1) {
      state.allConversations.splice(index, 1, {
        ...state.allConversations[index],
        ...conversation,
      });
    }
  },

  [types.SET_CURRENT_CONVERSATION](state, conversationId) {
    state.currentConversationId = conversationId;
  },

  [types.SET_CONVERSATION_FILTERS](state, filters) {
    state.conversationFilters = { ...state.conversationFilters, ...filters };
  },
};

// actions.js
import ConversationsAPI from '../../../api/conversations';
import types from '../../mutation-types';

export default {
  async fetch({ commit, state }, params = {}) {
    commit(types.SET_CONVERSATION_UI_FLAG, { key: 'isFetching', value: true });
    
    try {
      const { data } = await ConversationsAPI.get({
        ...state.conversationFilters,
        ...params,
      });
      
      commit(types.SET_CONVERSATIONS, data.data.payload);
      commit(types.SET_CONVERSATION_META, data.data.meta);
    } finally {
      commit(types.SET_CONVERSATION_UI_FLAG, { key: 'isFetching', value: false });
    }
  },

  async fetchMore({ commit, state }) {
    if (state.uiFlags.isFetchingMore) return;
    
    commit(types.SET_CONVERSATION_UI_FLAG, { key: 'isFetchingMore', value: true });
    
    try {
      const { data } = await ConversationsAPI.get({
        ...state.conversationFilters,
        page: state.meta.currentPage + 1,
      });
      
      data.data.payload.forEach((conversation) => {
        commit(types.ADD_CONVERSATION, conversation);
      });
      
      commit(types.SET_CONVERSATION_META, data.data.meta);
    } finally {
      commit(types.SET_CONVERSATION_UI_FLAG, { key: 'isFetchingMore', value: false });
    }
  },

  setCurrentConversation({ commit }, conversationId) {
    commit(types.SET_CURRENT_CONVERSATION, conversationId);
  },

  updateFilters({ commit, dispatch }, filters) {
    commit(types.SET_CONVERSATION_FILTERS, filters);
    dispatch('fetch');
  },

  // Called from WebSocket events
  addConversation({ commit }, conversation) {
    commit(types.ADD_CONVERSATION, conversation);
  },

  updateConversation({ commit }, conversation) {
    commit(types.UPDATE_CONVERSATION, conversation);
  },
};
```

## Store Initialization

```javascript
// app/javascript/dashboard/store/index.js
import { createStore } from 'vuex';

import auth from './modules/auth';
import accounts from './modules/accounts';
import conversations from './modules/conversations';
import contacts from './modules/contacts';
import inboxes from './modules/inboxes';
import labels from './modules/labels';
import notifications from './modules/notifications';

export default createStore({
  modules: {
    auth,
    accounts,
    conversations,
    contacts,
    inboxes,
    labels,
    notifications,
  },
});
```

## Testing Store

```javascript
// spec/javascript/dashboard/store/modules/labels.spec.js
import { describe, it, expect, vi, beforeEach } from 'vitest';
import labelsModule from 'dashboard/store/modules/labels';
import LabelsAPI from 'dashboard/api/labels';

vi.mock('dashboard/api/labels');

describe('Labels Store', () => {
  let state;
  let commit;

  beforeEach(() => {
    state = { records: [], uiFlags: { isFetching: false } };
    commit = vi.fn();
  });

  describe('actions', () => {
    describe('fetch', () => {
      it('fetches labels and commits them', async () => {
        const labels = [{ id: 1, title: 'Bug' }];
        LabelsAPI.get.mockResolvedValue({ data: labels });

        await labelsModule.actions.fetch({ commit });

        expect(commit).toHaveBeenCalledWith('SET_LABELS', labels);
      });

      it('sets loading state', async () => {
        LabelsAPI.get.mockResolvedValue({ data: [] });

        await labelsModule.actions.fetch({ commit });

        expect(commit).toHaveBeenCalledWith('SET_LABEL_UI_FLAG', {
          key: 'isFetching',
          value: true,
        });
        expect(commit).toHaveBeenCalledWith('SET_LABEL_UI_FLAG', {
          key: 'isFetching',
          value: false,
        });
      });
    });
  });

  describe('mutations', () => {
    it('SET_LABELS updates records', () => {
      const labels = [{ id: 1, title: 'Bug' }];
      
      labelsModule.mutations.SET_LABELS(state, labels);
      
      expect(state.records).toEqual(labels);
    });

    it('ADD_LABEL adds to records', () => {
      const label = { id: 1, title: 'Bug' };
      
      labelsModule.mutations.ADD_LABEL(state, label);
      
      expect(state.records).toContain(label);
    });
  });

  describe('getters', () => {
    it('getLabelById returns correct label', () => {
      state.records = [
        { id: 1, title: 'Bug' },
        { id: 2, title: 'Feature' },
      ];

      const getter = labelsModule.getters.getLabelById(state);
      
      expect(getter(1)).toEqual({ id: 1, title: 'Bug' });
    });
  });
});
```
