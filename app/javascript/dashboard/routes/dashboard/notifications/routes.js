/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../helper/URLHelper';
import SettingsWrapper from '../settings/Wrapper.vue';
import NotificationsView from './components/NotificationsView.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/notifications'),
    component: SettingsWrapper,
    props: {
      headerTitle: 'NOTIFICATIONS_PAGE.HEADER',
      icon: 'alert',
      showNewButton: false,
      showSidemenuIcon: false,
    },
    children: [
      {
        path: '',
        name: 'notifications_index',
        component: NotificationsView,
        meta: {
          permissions: ['administrator', 'agent', 'custom_role'],
        },
      },
    ],
  },
];
