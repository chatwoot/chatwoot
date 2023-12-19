import { getters } from './getters';
import { actions } from './actions';
import { mutations } from './mutations';

const state = {
  conversations: {},
  meta: {
    userLastSeenAt: undefined,
  },
  uiFlags: {
    allMessagesLoaded: false,
    isFetchingList: false,
    isAgentTyping: false,
    isCreating: false,
  },
  lastMessageId: null,
  totalCsat: 0,
  totalSubmittedCsat: 0,
  totalAnsweredCsat: 0,
  csatTemplateEnabled: false,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
