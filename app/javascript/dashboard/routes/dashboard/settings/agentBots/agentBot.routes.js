const Bot = () => import('./Index.vue');
const CsmlEditBot = () => import('./csml/Edit.vue');
const CsmlNewBot = () => import('./csml/New.vue');
import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = () => import('../Wrapper.vue');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/agent-bots'),
      meta: {
        permissions: ['account_manage'],
      },
      component: SettingsContent,
      props: {
        headerTitle: 'AGENT_BOTS.HEADER',
        icon: 'bot',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'agent_bots',
          component: Bot,
          meta: {
            permissions: ['account_manage'],
          },
        },
        {
          path: 'csml/new',
          name: 'agent_bots_csml_new',
          component: CsmlNewBot,
          meta: {
            permissions: ['account_manage'],
          },
        },
        {
          path: 'csml/:botId',
          name: 'agent_bots_csml_edit',
          component: CsmlEditBot,
          meta: {
            permissions: ['account_manage'],
          },
        },
      ],
    },
  ],
};
