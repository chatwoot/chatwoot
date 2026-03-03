import { frontendURL } from 'dashboard/helper/URLHelper.js';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import WhatsappFlowsRouteView from './pages/WhatsappFlowsRouteView.vue';
import WhatsappFlowsListPage from './pages/WhatsappFlowsListPage.vue';
import WhatsappFlowBuilderPage from './pages/WhatsappFlowBuilderPage.vue';

const meta = {
  featureFlag: FEATURE_FLAGS.WHATSAPP_TEMPLATE_BUILDER,
  permissions: ['administrator'],
};

const whatsappFlowsRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/whatsapp-flows'),
      component: WhatsappFlowsRouteView,
      children: [
        {
          path: '',
          name: 'whatsapp_flows_index',
          meta,
          component: WhatsappFlowsListPage,
        },
        {
          path: 'new',
          name: 'whatsapp_flows_new',
          meta,
          component: WhatsappFlowBuilderPage,
        },
        {
          path: ':flowId/edit',
          name: 'whatsapp_flows_edit',
          meta,
          component: WhatsappFlowBuilderPage,
        },
      ],
    },
  ],
};

export default whatsappFlowsRoutes;
