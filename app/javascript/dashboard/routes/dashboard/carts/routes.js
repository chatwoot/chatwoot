import { frontendURL } from '../../../helper/URLHelper';
import CartsIndex from 'dashboard/components-next/Carts/CartsIndex.vue';
import { FEATURE_FLAGS } from '../../../featureFlags';

const meta = {
  featureFlag: FEATURE_FLAGS.CRM,
  permissions: ['administrator', 'agent', 'contact_manage'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/carts'),
    name: 'carts_list',
    component: CartsIndex,
    meta,
  },
];
