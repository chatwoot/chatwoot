import { frontendURL } from '../../../helper/URLHelper';
import Index from './Index';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/social'),
    name: 'settings_account_social_bot',
    component: Index,
    roles: ['administrator', 'agent'],
  },
];
