import Vue from 'vue';
import Vuex from 'vuex';
import agent from 'widget/store/modules/agent';
import appConfig from 'widget/store/modules/appConfig';
import message from 'widget/store/modules/message';
import conversation from 'widget/store/modules/conversation';
import conversationLabels from 'widget/store/modules/conversationLabels';

Vue.use(Vuex);

export default new Vuex.Store({
  modules: {
    agent,
    appConfig,
    message,
    conversation,
    conversationLabels,
  },
});
