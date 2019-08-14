import SettingsContent from '../Wrapper';
import CannedHome from './Index';

export default {
  routes: [
    {
      path: '/u/settings/canned-response',
      component: SettingsContent,
      props: {
        headerTitle: 'CANNED_MGMT.HEADER',
        icon: 'ion-chatbox-working',
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
