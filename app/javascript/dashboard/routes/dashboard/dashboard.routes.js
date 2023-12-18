import settings from './settings/settings.routes';
import conversation from './conversation/conversation.routes';
import { routes as searchRoutes } from '../../modules/search/search.routes';
import { routes as contactRoutes } from './contacts/routes';
import { routes as notificationRoutes } from './notifications/routes';
import { frontendURL } from '../../helper/URLHelper';
import helpcenterRoutes from './helpcenter/helpcenter.routes';

const AppContainer = () => import('./Dashboard.vue');
const Suspended = () => import('./suspended/Index.vue');
const SetupProfile = () => import('./start/SetupProfile.vue');
const SetupCompany = () => import('./start/SetupCompany.vue');
const FoundersNote = () => import('./start/FoundersNote.vue');
const InviteTeam = () => import('./start/InviteTeam.vue');

export default {
  routes: [
    ...helpcenterRoutes.routes,
    {
      path: frontendURL('accounts/:account_id'),
      component: AppContainer,
      children: [
        ...conversation.routes,
        ...settings.routes,
        ...contactRoutes,
        ...searchRoutes,
        ...notificationRoutes,
      ],
    },
    {
      path: frontendURL('accounts/:accountId/suspended'),
      name: 'account_suspended',
      roles: ['administrator', 'agent'],
      component: Suspended,
    },
    {
      path: frontendURL('start/setup-profile'),
      name: 'onboarding_setup_profile',
      component: SetupProfile,
    },
    {
      path: frontendURL('start/setup-company'),
      name: 'onboarding_setup_company',
      component: SetupCompany,
    },
    {
      path: frontendURL('start/founders-note'),
      name: 'onboarding_founders_note',
      component: FoundersNote,
    },
    {
      path: frontendURL('start/invite-team'),
      name: 'onboarding_invite-team',
      component: InviteTeam,
    },
  ],
};
