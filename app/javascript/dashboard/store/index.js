import Vue from 'vue';
import Vuex from 'vuex';

import * as getters from './getters';

import auth from './modules/auth';
import conversations from './modules/conversations';
import sideMenuItems from './modules/sidebar';
import AccountState from './modules/AccountState';
import Channel from './modules/channels';
import cannedResponse from './modules/cannedResponse';
import reports from './modules/reports';
import billing from './modules/billing';

Vue.use(Vuex);
export default new Vuex.Store({
  getters,
  modules: {
    auth,
    conversations,
    sideMenuItems,
    AccountState,
    Channel,
    cannedResponse,
    reports,
    billing,
  },
});
