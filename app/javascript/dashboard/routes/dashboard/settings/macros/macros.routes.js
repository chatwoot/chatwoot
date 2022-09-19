import SettingsContent from '../Wrapper';
import Macros from './Index';
const NewMacro = () => import('./New.vue');
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/macros'),
      component: SettingsContent,
      props: {
        headerTitle: 'MACROS.HEADER',
        icon: 'macros',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'macros_wrapper',
          component: Macros,
          roles: ['administrator'],
        },
        {
          path: 'new',
          name: 'macros_new',
          component: NewMacro,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
