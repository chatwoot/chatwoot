import Vue from 'vue';
import Vuex from 'vuex';
import appConfig from 'widget/store/modules/appConfig';
import contact from 'widget/store/modules/contact';
import conversation from 'widget/store/modules/conversation';
import agent from 'widget/store/modules/agent';
import events from 'widget/store/modules/events';

Vue.use(Vuex);

export default new Vuex.Store({
  modules: {
    appConfig,
    contact,
    conversation,
    agent,
    events,
  },
});
