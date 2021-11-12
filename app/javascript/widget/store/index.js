import Vue from 'vue';
import Vuex from 'vuex';
import agent from 'widget/store/modules/agent';
import appConfig from 'widget/store/modules/appConfig';

import conversationLabels from 'widget/store/modules/conversationLabels';
import events from 'widget/store/modules/events';
import globalConfig from 'shared/store/globalConfig';
import campaign from 'widget/store/modules/campaign';

// New store modules
import contact from './modules/contact/index.js';
import conversation from './modules/conversation/index.js';
import message from './modules/message/index.js';

Vue.use(Vuex);
export default new Vuex.Store({
  modules: {
    agent,
    appConfig,
    conversationLabels,
    events,
    globalConfig,
    campaign,
    contact,
    conversation,
    message,
  },
});
