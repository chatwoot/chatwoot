import { frontendURL } from '../../../helper/URLHelper';
import AppointmentsIndex from './AppointmentsIndex.vue';
import { FEATURE_FLAGS } from '../../../featureFlags';

const meta = {
  featureFlag: FEATURE_FLAGS.CRM,
  permissions: ['administrator', 'agent', 'contact_manage'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/appointments'),
    name: 'appointments_index',
    component: AppointmentsIndex,
    meta,
  },
];
