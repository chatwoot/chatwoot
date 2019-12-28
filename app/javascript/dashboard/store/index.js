import Vue from 'vue';
import Vuex from 'vuex';

import agents from './modules/agents';
import auth from './modules/auth';
import billing from './modules/billing';
import cannedResponse from './modules/cannedResponse';
import Channel from './modules/channels';
import conversations from './modules/conversations';
import inboxes from './modules/inboxes';
import inboxMembers from './modules/inboxMembers';
import reports from './modules/reports';

Vue.use(Vuex);
export default new Vuex.Store({
  modules: {
    agents,
    auth,
    billing,
    cannedResponse,
    Channel,
    conversations,
    inboxes,
    inboxMembers,
    reports,
  },
});
