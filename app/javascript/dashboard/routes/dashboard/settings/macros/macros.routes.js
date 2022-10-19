import SettingsContent from '../Wrapper';
import Macros from './Index';
const MacroEditor = () => import('./MacroEditor');
import { frontendURL } from 'dashboard/helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/macros'),
      component: SettingsContent,
      props: {
        headerTitle: 'MACROS.HEADER',
        icon: 'flash-settings',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'macros_wrapper',
          component: Macros,
          roles: ['administrator', 'agent'],
        },
        {
          path: 'new',
          name: 'macros_new',
          component: MacroEditor,
          roles: ['administrator', 'agent'],
        },
        {
          path: ':macroId/edit',
          name: 'macros_edit',
          component: MacroEditor,
          roles: ['administrator', 'agent'],
        },
      ],
    },
  ],
};
