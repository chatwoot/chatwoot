import { frontendURL } from '../../../helper/URLHelper';
import ContactsIndex from './pages/ContactsIndex.vue';
import ContactManageView from './pages/ContactManageView.vue';
import { FEATURE_FLAGS } from '../../../featureFlags';

const commonMeta = {
  featureFlag: FEATURE_FLAGS.CRM,
  permissions: ['administrator', 'agent', 'contact_manage'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/contacts'),
    name: 'contacts_dashboard_index',
    component: ContactsIndex,
    meta: commonMeta,
  },
  {
    path: frontendURL('accounts/:accountId/contacts/segments/:segmentId'),
    name: 'contacts_dashboard_segments_index',
    component: ContactsIndex,
    meta: commonMeta,
  },
  {
    path: frontendURL('accounts/:accountId/contacts/labels/:label'),
    name: 'contacts_dashboard_labels_index',
    component: ContactsIndex,
    meta: commonMeta,
  },
  {
    path: frontendURL('accounts/:accountId/contacts/active'),
    name: 'contacts_dashboard_active',
    component: ContactsIndex,
    meta: commonMeta,
  },
  {
    path: frontendURL('accounts/:accountId/contacts/:contactId'),
    name: 'contacts_edit',
    component: ContactManageView,
    meta: commonMeta,
  },
  {
    path: frontendURL(
      'accounts/:accountId/contacts/:contactId/segments/:segmentId'
    ),
    name: 'contacts_edit_segment',
    component: ContactManageView,
    meta: commonMeta,
  },
  {
    path: frontendURL('accounts/:accountId/contacts/:contactId/labels/:label'),
    name: 'contacts_edit_label',
    component: ContactManageView,
    meta: commonMeta,
  },
];
