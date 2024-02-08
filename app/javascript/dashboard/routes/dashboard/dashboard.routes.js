import settings from './settings/settings.routes';
import conversation from './conversation/conversation.routes';
import { routes as searchRoutes } from '../../modules/search/search.routes';
import { routes as contactRoutes } from './contacts/routes';
import { routes as notificationRoutes } from './notifications/routes';
import { frontendURL } from '../../helper/URLHelper';
import helpcenterRoutes from './helpcenter/helpcenter.routes';

const AppContainer = () => import('./Dashboard.vue');
const Suspended = () => import('./suspended/Index.vue');
// const SetupProfile = () => import('v3/views/onboarding/SetupProfile.vue');
// const SetupCompany = () => import('v3/views/onboarding/SetupCompany.vue');
// const InviteTeam = () => import('v3/views/onboarding/InviteTeam.vue');
// const FoundersNote = () => import('v3/views/onboarding/FoundersNote.vue');
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
    // {
    //   path: frontendURL('accounts/:account_id/start/setup-profile'),
    //   name: 'onboarding_setup_profile',
    //   component: SetupProfile,
    // },
    // {
    //   path: frontendURL('accounts/:account_id/start/setup-company'),
    //   name: 'onboarding_setup_company',
    //   component: SetupCompany,
    // },
    // {
    //   path: frontendURL('accounts/:account_id/start/invite-team'),
    //   name: 'onboarding_invite_team',
    //   component: InviteTeam,
    // },
    // {
    //   path: frontendURL('accounts/:account_id/start/founders-note'),
    //   name: 'onboarding_fouunders_note',
    //   component: FoundersNote,
    // },
  ],
};
