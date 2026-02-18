import { frontendURL } from '../../../helper/URLHelper';
import AppointmentsIndex from './pages/Index.vue';

const appointmentsMeta = {
  permissions: ['administrator', 'supervisor', 'agent', 'contact_manage'],
};

export const routes = [
  {
    path: frontendURL('accounts/:accountId/appointments'),
    name: 'appointments_dashboard',
    component: AppointmentsIndex,
    meta: appointmentsMeta,
  },
];
