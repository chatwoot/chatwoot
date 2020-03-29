import Vue from 'vue';
import Vuex from 'vuex';
import agent from 'widget/store/modules/agent';
import appConfig from 'widget/store/modules/appConfig';
import contact from 'widget/store/modules/contact';
import conversation from 'widget/store/modules/conversation';
import conversationLabels from 'widget/store/modules/conversationLabels';

Vue.use(Vuex);

export default new Vuex.Store({
  modules: {
    agent,
    appConfig,
    contact,
    conversation,
    conversationLabels,
  },
});
