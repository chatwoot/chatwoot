import Index from './Index';
import SettingsContent from '../Wrapper';

export default {
  routes: [
    {
      path: '/u/reports',
      component: SettingsContent,
      props: {
        headerTitle: 'REPORT.HEADER',
        headerButtonText: 'REPORT.HEADER_BTN_TXT',
        icon: 'ion-arrow-graph-up-right',
      },
      children: [
        {
          path: '',
          name: 'settings_account_reports',
          roles: ['administrator'],
          component: Index,
        },
      ],
    },
  ],
};
