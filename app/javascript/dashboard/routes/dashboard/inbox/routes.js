/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../helper/URLHelper';
const SettingsWrapper = () => import('../settings/Wrapper.vue');
const InboxView = () => import('./components/InboxView.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/inbox'),
    component: SettingsWrapper,
    props: {
      headerTitle: 'INBOX_PAGE.HEADER',
      icon: 'alert',
      showNewButton: false,
      showSidemenuIcon: false,
    },
    children: [
      {
        path: '',
        name: 'inbox_index',
        component: InboxView,
        roles: ['administrator', 'agent'],
      },
    ],
  },
];
