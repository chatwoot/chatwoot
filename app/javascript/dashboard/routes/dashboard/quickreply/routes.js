// app/javascript/dashboard/routes/dashboard/quickreply/quickreply.routes.js

import { frontendURL } from '../../../helper/URLHelper';
import QuickReplyManageView from './pages/QuickReplyManageView.vue';

const QUICK_REPLY_PERMISSIONS = ['administrator', 'agent'];

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/quick-replies'),
      name: 'quick_reply_manage',
      meta: {
        permissions: QUICK_REPLY_PERMISSIONS,
      },
      component: QuickReplyManageView,
    },
  ],
};
