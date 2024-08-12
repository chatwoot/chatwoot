import { frontendURL } from 'dashboard/helper/URLHelper';

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
          meta: {
            permissions: ['administrator', 'agent'],
          },
        },
        {
          path: 'new',
          name: 'macros_new',
          component: MacroEditor,
          meta: {
            permissions: ['administrator', 'agent'],
          },
        },
        {
          path: ':macroId/edit',
          name: 'macros_edit',
          component: MacroEditor,
          meta: {
            permissions: ['administrator', 'agent'],
          },
        },
      ],
    },
  ],
};
