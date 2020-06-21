import SettingsContent from '../Wrapper';
import Index from './Index';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/labels'),
      component: SettingsContent,
      props: {
        headerTitle: 'LABEL_MGMT.HEADER',
        icon: 'ion-pricetags',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'labels_wrapper',
          roles: ['administrator'],
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'labels_list',
          roles: ['administrator'],
          component: Index,
        },
      ],
    },
  ],
};
