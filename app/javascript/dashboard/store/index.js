import Vue from 'vue';
import Vuex from 'vuex';

import accounts from './modules/accounts';
import agents from './modules/agents';
import auth from './modules/auth';
import cannedResponse from './modules/cannedResponse';
import Channel from './modules/channels';
import contactConversations from './modules/contactConversations';
import contacts from './modules/contacts';
import conversationLabels from './modules/conversationLabels';
import conversationMetadata from './modules/conversationMetadata';
import conversationPage from './modules/conversationPage';
import conversations from './modules/conversations';
import conversationTypingStatus from './modules/conversationTypingStatus';
import globalConfig from 'shared/store/globalConfig';
import inboxes from './modules/inboxes';
import inboxMembers from './modules/inboxMembers';
import reports from './modules/reports';
import userNotificationSettings from './modules/userNotificationSettings';
import webhooks from './modules/webhooks';

Vue.use(Vuex);
export default new Vuex.Store({
  modules: {
    accounts,
    agents,
    auth,
    cannedResponse,
    Channel,
    contactConversations,
    contacts,
    conversationLabels,
    conversationMetadata,
    conversationPage,
    conversations,
    conversationTypingStatus,
    globalConfig,
    inboxes,
    inboxMembers,
    reports,
    userNotificationSettings,
    webhooks,
  },
});
