import { frontendURL } from '../../../helper/URLHelper';
import PaymentLinksIndex from '../contacts/pages/PaymentLinksIndex.vue';
import { FEATURE_FLAGS } from '../../../featureFlags';

const meta = {
  featureFlag: FEATURE_FLAGS.CRM,
  permissions: ['administrator', 'agent', 'contact_manage'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/payment-links'),
    name: 'payment_links',
    component: PaymentLinksIndex,
    meta,
  },
];
