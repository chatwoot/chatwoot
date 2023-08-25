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
import article from 'widget/store/modules/articles';

import VuexORM from '@vuex-orm/core';
import VuexORMAxios from '@vuex-orm/plugin-axios';

import Message from './modules/models/Message';
import Conversation from './modules/models/Conversation';
import ConversationMeta from './modules/models/ConversationMeta';
import MessageMeta from './modules/models/MessageMeta';
import UiFlag from './modules/models/UiFlag';
import { API } from 'widget/helpers/axios';

import conversationV3 from 'widget/store/modules/conversationV3';
import messageV3 from 'widget/store/modules/messageV3';

Vue.use(Vuex);

VuexORM.use(VuexORMAxios, { axios: API });
const database = new VuexORM.Database();

database.register(Message);
database.register(Conversation);
database.register(ConversationMeta);
database.register(MessageMeta);
database.register(UiFlag);

export default new Vuex.Store({
  plugins: [VuexORM.install(database)],
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
    article,
    conversationV3,
    messageV3,
  },
});
