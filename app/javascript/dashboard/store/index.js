import { createStore } from 'vuex';

import accounts from './modules/accounts';
import agentBots from './modules/agentBots';
import agents from './modules/agents';
import articles from './modules/helpCenterArticles';
import attributes from './modules/attributes';
import auditlogs from './modules/auditlogs';
import auth from './modules/auth';
import automations from './modules/automations';
import bulkActions from './modules/bulkActions';
import campaigns from './modules/campaigns';
import cannedResponse from './modules/cannedResponse';
import categories from './modules/helpCenterCategories';
import contactConversations from './modules/contactConversations';
import contactLabels from './modules/contactLabels';
import contactNotes from './modules/contactNotes';
import contacts from './modules/contacts';
import conversationLabels from './modules/conversationLabels';
import conversationMetadata from './modules/conversationMetadata';
import conversationPage from './modules/conversationPage';
import conversations from './modules/conversations';
import conversationSearch from './modules/conversationSearch';
import conversationStats from './modules/conversationStats';
import conversationTypingStatus from './modules/conversationTypingStatus';
import conversationWatchers from './modules/conversationWatchers';
import csat from './modules/csat';
import customRole from './modules/customRole';
import customViews from './modules/customViews';
import dashboardApps from './modules/dashboardApps';
import draftMessages from './modules/draftMessages';
import globalConfig from 'shared/store/globalConfig';
import inboxAssignableAgents from './modules/inboxAssignableAgents';
import inboxes from './modules/inboxes';
import inboxMembers from './modules/inboxMembers';
import integrations from './modules/integrations';
import labels from './modules/labels';
import macros from './modules/macros';
import notifications from './modules/notifications';
import portals from './modules/helpCenterPortals';
import reports from './modules/reports';
import sla from './modules/sla';
import slaReports from './modules/SLAReports';
import summaryReports from './modules/summaryReports';
import teamMembers from './modules/teamMembers';
import teams from './modules/teams';
import userNotificationSettings from './modules/userNotificationSettings';
import webhooks from './modules/webhooks';
import captainAssistants from './captain/assistant';
import captainDocuments from './captain/document';
import captainResponses from './captain/response';
import captainInboxes from './captain/inboxes';
import captainBulkActions from './captain/bulkActions';
import copilotThreads from './captain/copilotThreads';
import copilotMessages from './captain/copilotMessages';

const plugins = [];

export default createStore({
  modules: {
    accounts,
    agentBots,
    agents,
    articles,
    attributes,
    auditlogs,
    auth,
    automations,
    bulkActions,
    campaigns,
    cannedResponse,
    categories,
    contactConversations,
    contactLabels,
    contactNotes,
    contacts,
    conversationLabels,
    conversationMetadata,
    conversationPage,
    conversations,
    conversationSearch,
    conversationStats,
    conversationTypingStatus,
    conversationWatchers,
    csat,
    customRole,
    customViews,
    dashboardApps,
    draftMessages,
    globalConfig,
    inboxAssignableAgents,
    inboxes,
    inboxMembers,
    integrations,
    labels,
    macros,
    notifications,
    portals,
    reports,
    sla,
    slaReports,
    summaryReports,
    teamMembers,
    teams,
    userNotificationSettings,
    webhooks,
    captainAssistants,
    captainDocuments,
    captainResponses,
    captainInboxes,
    captainBulkActions,
    copilotThreads,
    copilotMessages,
  },
  plugins,
});
