import SettingsContent from '../Wrapper';
import StatusHome from './Index';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/status'),
      component: SettingsContent,
      props: {
        headerTitle: 'STATUS_MGMT.HEADER',
        icon: 'ion-chatbox-working',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'status_wrapper',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'status_list',
          roles: ['administrator', 'agent'],
          component: StatusHome,
        },
      ],
    },
  ],
};
