import Vue from 'vue';
import Vuex from 'vuex';
import agent from 'widget/store/modules/agent';
import appConfig from 'widget/store/modules/appConfig';

import conversationLabels from 'widget/store/modules/conversationLabels';
import events from 'widget/store/modules/events';
import globalConfig from 'shared/store/globalConfig';
import campaign from 'widget/store/modules/campaign';

// New store modules
import contactV2 from './modules/contactV2/index.js';
import conversationV2 from './modules/conversationNew/index.js';
import messageV2 from './modules/messageV2/index.js';

Vue.use(Vuex);
export default new Vuex.Store({
  modules: {
    agent,
    appConfig,
    conversationLabels,
    events,
    globalConfig,
    campaign,
    contactV2,
    conversationV2,
    messageV2,
  },
});
