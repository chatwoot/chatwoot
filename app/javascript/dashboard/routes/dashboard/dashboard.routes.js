import settings from './settings/settings.routes';
import conversation from './conversation/conversation.routes';
import { routes as searchRoutes } from '../../modules/search/search.routes';
import { routes as contactRoutes } from './contacts/routes';
import { routes as notificationRoutes } from './notifications/routes';
import { routes as inboxRoutes } from './inbox/routes';
import { frontendURL } from '../../helper/URLHelper';
import helpcenterRoutes from './helpcenter/helpcenter.routes';
import campaignsRoutes from './campaigns/campaigns.routes';
import { routes as captainRoutes } from './captain/captain.routes';
import AppContainer from './Dashboard.vue';
import Suspended from './suspended/Index.vue';
import RouteLayout from 'v3/views/onboarding/RouteLayout.vue';
import SetupProfile from 'v3/views/onboarding/SetupProfile.vue';
import AddAgent from 'v3/views/onboarding/AddAgent.vue';
import InboxChannels from 'v3/views/onboarding/InboxChannels.vue';
import InboxConfigure from 'v3/views/onboarding/InboxConfigure.vue';
import InboxAddAgents from 'v3/views/onboarding/InboxAddAgents.vue';
import InboxFinishSetup from 'v3/views/onboarding/InboxFinishSetup.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId'),
      component: AppContainer,
      children: [
        ...captainRoutes,
        ...inboxRoutes,
        ...conversation.routes,
        ...settings.routes,
        ...contactRoutes,
        ...searchRoutes,
        ...notificationRoutes,
        ...helpcenterRoutes.routes,
        ...campaignsRoutes.routes,
      ],
    },
    {
      path: frontendURL('accounts/:accountId/suspended'),
      name: 'account_suspended',
      meta: {
        permissions: ['administrator', 'agent', 'custom_role'],
      },
      component: Suspended,
    },
    {
      path: frontendURL('accounts/:accountId/start'),
      meta: {
        permissions: ['administrator'],
      },
      component: RouteLayout,
      children: [
        {
          path: frontendURL('accounts/:accountId/start/setup-profile'),
          name: 'onboarding_setup_profile',
          meta: {
            permissions: ['administrator'],
          },
          component: SetupProfile,
        },
        {
          path: frontendURL('accounts/:accountId/start/add-agent'),
          name: 'onboarding_add_agent',
          meta: {
            permissions: ['administrator'],
          },
          component: AddAgent,
        },
        {
          path: frontendURL('accounts/:accountId/start/setup-inbox'),
          name: 'onboarding_setup_inbox',
          meta: {
            permissions: ['administrator'],
          },
          component: InboxChannels,
        },
        {
          path: frontendURL(
            'accounts/:accountId/start/setup-inbox/configure/:channel'
          ),
          name: 'onboarding_setup_inbox_configure',
          meta: {
            permissions: ['administrator'],
          },
          component: InboxConfigure,
          props: route => {
            return { channel: route.params.channel };
          },
        },
        {
          path: frontendURL(
            'accounts/:accountId/start/setup-inbox/add-agents/:inbox_id'
          ),
          name: 'onboarding_setup_inbox_add_agents',
          meta: {
            permissions: ['administrator'],
          },
          component: InboxAddAgents,
          props: route => {
            return { inbox_id: route.params.inbox_id };
          },
        },
        {
          path: frontendURL(
            'accounts/:accountId/start/setup-inbox/finish/:inbox_id'
          ),
          name: 'onboarding_setup_inbox_finish',
          meta: {
            permissions: ['administrator'],
          },
          component: InboxFinishSetup,
          props: route => {
            return { inbox_id: route.params.inbox_id };
          },
        },
      ],
    },
  ],
};
