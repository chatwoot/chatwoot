import Vue from 'vue';
import Vuex from 'vuex';

import accounts from './modules/accounts';
import agents from './modules/agents';
import auth from './modules/auth';
import cannedResponse from './modules/cannedResponse';
import contactConversations from './modules/contactConversations';
import contacts from './modules/contacts';
import notifications from './modules/notifications';
import conversationLabels from './modules/conversationLabels';
import conversationMetadata from './modules/conversationMetadata';
import conversationPage from './modules/conversationPage';
import conversations from './modules/conversations';
import conversationSearch from './modules/conversationSearch';
import conversationStats from './modules/conversationStats';
import conversationTypingStatus from './modules/conversationTypingStatus';
import globalConfig from 'shared/store/globalConfig';
import inboxes from './modules/inboxes';
import inboxMembers from './modules/inboxMembers';
import integrations from './modules/integrations';
import labels from './modules/labels';
import reports from './modules/reports';
import userNotificationSettings from './modules/userNotificationSettings';
import webhooks from './modules/webhooks';
import teams from './modules/teams';
import teamMembers from './modules/teamMembers';

Vue.use(Vuex);
export default new Vuex.Store({
  modules: {
    accounts,
    agents,
    auth,
    cannedResponse,
    contactConversations,
    contacts,
    notifications,
    conversationLabels,
    conversationMetadata,
    conversationPage,
    conversations,
    conversationSearch,
    conversationStats,
    conversationTypingStatus,
    globalConfig,
    inboxes,
    inboxMembers,
    integrations,
    labels,
    reports,
    userNotificationSettings,
    webhooks,
    teams,
    teamMembers,
  },
});
