import { frontendURL } from 'dashboard/helper/URLHelper.js';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import MessageTemplatesRouteView from './pages/MessageTemplatesRouteView.vue';
import MessageTemplatesListPage from './pages/MessageTemplatesListPage.vue';
import MessageTemplateBuilderPage from './pages/MessageTemplateBuilderPage.vue';

const meta = {
  featureFlag: FEATURE_FLAGS.WHATSAPP_TEMPLATE_BUILDER,
  permissions: ['administrator'],
};

const messageTemplatesRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/message-templates'),
      component: MessageTemplatesRouteView,
      children: [
        {
          path: '',
          name: 'message_templates_index',
          meta,
          component: MessageTemplatesListPage,
        },
        {
          path: 'new',
          name: 'message_templates_new',
          meta,
          component: MessageTemplateBuilderPage,
        },
        {
          path: ':templateId/edit',
          name: 'message_templates_edit',
          meta,
          component: MessageTemplateBuilderPage,
        },
      ],
    },
  ],
};

export default messageTemplatesRoutes;
