import Vue from 'vue';
import Vuex from 'vuex';
import agent from 'widget/store/modules/agent';
import appConfig from 'widget/store/modules/appConfig';
import contacts from 'widget/store/modules/contacts';
import conversation from 'widget/store/modules/conversation';
import conversationLabels from 'widget/store/modules/conversationLabels';
import events from 'widget/store/modules/events';
import message from 'widget/store/modules/message';

Vue.use(Vuex);

export default new Vuex.Store({
  modules: {
    agent,
    appConfig,
    contacts,
    conversation,
    conversationLabels,
    events,
    message,
  },
});
