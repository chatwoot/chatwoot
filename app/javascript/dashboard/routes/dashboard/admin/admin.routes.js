import { frontendURL } from '../../../helper/URLHelper';
import AdminConsole from './pages/AdminConsole.vue';
import AdminConversations from './pages/AdminConversations.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/admin'),
      name: 'admin_console',
      component: AdminConsole,
      meta: {
        permissions: ['administrator'],
      },
    },
    {
      path: frontendURL('accounts/:accountId/admin/conversations'),
      name: 'admin_conversations',
      component: AdminConversations,
      meta: {
        permissions: ['administrator'],
      },
    },
  ],
};

