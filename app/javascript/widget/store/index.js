import Vue from 'vue';
import Vuex from 'vuex';
import agent from 'widget/store/modules/agent';
import appConfig from 'widget/store/modules/appConfig';
import contacts from 'widget/store/modules/contacts';
import conversation from 'widget/store/modules/conversation';
import conversationAttributes from 'widget/store/modules/conversationAttributes';
import conversationLabels from 'widget/store/modules/conversationLabels';
import events from 'widget/store/modules/events';
import globalConfig from 'shared/store/globalConfig';
import message from 'widget/store/modules/message';
import campaign from 'widget/store/modules/campaign';

// New store modules
import contactV2 from './modules/contactV2/index.js';
import conversationV2 from './modules/conversationV2/index.js';
import messageV2 from './modules/messageV2/index.js';

Vue.use(Vuex);
export default new Vuex.Store({
  modules: {
    agent,
    appConfig,
    contacts,
    conversation,
    conversationAttributes,
    conversationLabels,
    events,
    globalConfig,
    message,
    campaign,
    contactV2,
    conversationV2,
    messageV2,
  },
});
