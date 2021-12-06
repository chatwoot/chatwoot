import SettingsContent from '../Wrapper';
import CannedHome from './Index';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/canned-response'),
      component: SettingsContent,
      props: {
        headerTitle: 'CANNED_MGMT.HEADER',
        icon: 'chat-multiple',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'canned_wrapper',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'canned_list',
          roles: ['administrator', 'agent'],
          component: CannedHome,
        },
      ],
    },
  ],
};
