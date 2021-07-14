import Index from './Index';
import CsatResponses from './CsatResponses';
import SettingsContent from '../Wrapper';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'REPORT.HEADER',
        icon: 'ion-arrow-graph-up-right',
      },
      children: [
        {
          path: '',
          redirect: 'overview',
        },
        {
          path: 'overview',
          name: 'settings_account_reports',
          roles: ['administrator'],
          component: Index,
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/reports'),
      component: SettingsContent,
      props: {
        headerTitle: 'CSAT_REPORTS.HEADER',
        icon: 'ion-happy-outline',
      },
      children: [
        {
          path: 'csat',
          name: 'csat_reports',
          roles: ['administrator'],
          component: CsatResponses,
        },
      ],
    },
  ],
};
