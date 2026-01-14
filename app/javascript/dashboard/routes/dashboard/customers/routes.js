import { frontendURL } from '../../../helper/URLHelper';
import CustomerManageView from './pages/CustomerManageView.vue';

const commonMeta = {
  permissions: ['administrator', 'supervisor', 'agent', 'contact_manage'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/customers/:contactId'),
    component: CustomerManageView,
    name: 'customer_edit',
    meta: commonMeta,
  },
];
