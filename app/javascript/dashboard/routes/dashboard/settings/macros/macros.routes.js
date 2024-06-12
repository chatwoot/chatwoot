import { frontendURL } from 'dashboard/helper/URLHelper';
import { AllRoles } from '../../../../featureFlags';

const SettingsContent = () => import('../Wrapper.vue');
const Macros = () => import('./Index.vue');
const MacroEditor = () => import('./MacroEditor.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/macros'),
      component: SettingsContent,
      props: params => {
        const showBackButton = params.name !== 'macros_wrapper';
        return {
          headerTitle: 'MACROS.HEADER',
          headerButtonText: 'MACROS.HEADER_BTN_TXT',
          icon: 'flash-settings',
          showBackButton,
        };
      },
      children: [
        {
          path: '',
          name: 'macros_wrapper',
          component: Macros,
          roles: AllRoles,
        },
        {
          path: 'new',
          name: 'macros_new',
          component: MacroEditor,
          roles: AllRoles,
        },
        {
          path: ':macroId/edit',
          name: 'macros_edit',
          component: MacroEditor,
          roles: AllRoles,
        },
      ],
    },
  ],
};
