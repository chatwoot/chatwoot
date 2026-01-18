const initialState = () => ({
  name: '',
  description: '',
  tone: 'friendly',
  formality: 'medium',
  empathy_level: 'medium',
  verbosity: 'balanced',
  emoji_usage: 'minimal',
  greeting_style: 'warm',
  custom_greeting: '',
  language: 'en',
  dialect: '',
  personality_description: '',
  documents: [],
  inbox_ids: [],
});

const getters = {
  getWizardData: state => state,
  getName: state => state.name,
  getDescription: state => state.description,
  getDocuments: state => state.documents,
  getInboxIds: state => state.inbox_ids,
};

const mutations = {
  SET_FIELD(state, { field, value }) {
    state[field] = value;
  },
  ADD_DOCUMENT(state, document) {
    state.documents.push(document);
  },
  REMOVE_DOCUMENT(state, index) {
    state.documents.splice(index, 1);
  },
  TOGGLE_INBOX(state, inboxId) {
    const index = state.inbox_ids.indexOf(inboxId);
    if (index === -1) {
      state.inbox_ids.push(inboxId);
    } else {
      state.inbox_ids.splice(index, 1);
    }
  },
  RESET(state) {
    Object.assign(state, initialState());
  },
};

const actions = {
  updateField({ commit }, { field, value }) {
    commit('SET_FIELD', { field, value });
  },
  addDocument({ commit }, document) {
    commit('ADD_DOCUMENT', document);
  },
  removeDocument({ commit }, index) {
    commit('REMOVE_DOCUMENT', index);
  },
  toggleInbox({ commit }, inboxId) {
    commit('TOGGLE_INBOX', inboxId);
  },
  reset({ commit }) {
    commit('RESET');
  },
};

export default {
  namespaced: true,
  state: initialState,
  getters,
  mutations,
  actions,
};
