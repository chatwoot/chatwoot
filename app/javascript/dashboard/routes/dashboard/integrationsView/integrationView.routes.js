/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../helper/URLHelper';
const IntegrationsView = () => import('./components/integrationsView.vue');
const OrdersManageView = () => import('./pages/OrdersManageView.vue');
const CorruptedContactsView = () => import('./pages/CorruptedContactsView.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/integrations-view'),
    name: 'integrations_view',
    meta: {
      permissions: ['administrator', 'agent'],
    },
    component: IntegrationsView,
  },
  {
    path: frontendURL('accounts/:accountId/integrations-view/:orderId'),
    name: 'integrations_details_view',
    meta: {
      permissions: ['administrator', 'agent'],
    },
    component: OrdersManageView,
    props: route => {
      return { orderId: route.params.orderId };
    },
  },
  {
    path: frontendURL('accounts/:accountId/integrations-view/corrupted/list'),
    name: 'integrations_corrupted_contacts',
    meta: {
      permissions: ['administrator', 'agent'],
    },
    component: CorruptedContactsView,
  },
];
