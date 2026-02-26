import { frontendURL } from '../../../helper/URLHelper';
import OrdersIndex from 'dashboard/components-next/Orders/OrdersIndex.vue';
import OrderDetailView from 'dashboard/components-next/Orders/OrderDetailView.vue';
import { FEATURE_FLAGS } from '../../../featureFlags';

const meta = {
  featureFlag: FEATURE_FLAGS.CRM,
  permissions: ['administrator', 'agent', 'contact_manage'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/orders'),
    name: 'orders_list',
    component: OrdersIndex,
    meta,
  },
  {
    path: frontendURL('accounts/:accountId/orders/:orderId'),
    name: 'orders_show',
    component: OrderDetailView,
    meta,
  },
];
