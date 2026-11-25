import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';
import messages from './messages';
import polls from './polls';
import drafts from './drafts';
import search from './search';
import { initialState } from './state';

const state = initialState();

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
  modules: {
    messages,
    polls,
    drafts,
    search,
  },
};
