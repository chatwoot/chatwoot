import SettingsContent from '../Wrapper.vue';
import AttributesHome from './Index.vue';
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/custom-attributes'),
      component: SettingsContent,
      props: {
        headerTitle: 'ATTRIBUTES_MGMT.HEADER',
        icon: 'code',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'attributes_wrapper',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'attributes_list',
          component: AttributesHome,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
