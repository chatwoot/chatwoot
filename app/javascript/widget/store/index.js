import Vue from 'vue';
import Vuex from 'vuex';
import agent from 'widget/store/modules/agent';
import appConfig from 'widget/store/modules/appConfig';
import contacts from 'widget/store/modules/contacts';
import conversation from 'widget/store/modules/conversation';
import conversationAttributes from 'widget/store/modules/conversationAttributes';
import events from 'widget/store/modules/events';
import globalConfig from 'shared/store/globalConfig';
import message from 'widget/store/modules/message';
import conversations from './modules/conversations';
Vue.use(Vuex);

export default new Vuex.Store({
  modules: {
    agent,
    appConfig,
    contacts,
    conversation,
    conversationAttributes,
    events,
    globalConfig,
    message,
    conversations,
  },
});
