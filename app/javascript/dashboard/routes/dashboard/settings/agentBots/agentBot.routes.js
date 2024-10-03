import { defineAsyncComponent } from 'vue';
const Bot = defineAsyncComponent(() => import('./Index.vue'));
const CsmlEditBot = defineAsyncComponent(() => import('./csml/Edit.vue'));
const CsmlNewBot = defineAsyncComponent(() => import('./csml/New.vue'));
import { frontendURL } from '../../../../helper/URLHelper';
const SettingsContent = defineAsyncComponent(() => import('../Wrapper.vue'));

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/agent-bots'),
      meta: {
        permissions: ['administrator'],
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
            permissions: ['administrator'],
          },
        },
        {
          path: 'csml/new',
          name: 'agent_bots_csml_new',
          component: CsmlNewBot,
          meta: {
            permissions: ['administrator'],
          },
        },
        {
          path: 'csml/:botId',
          name: 'agent_bots_csml_edit',
          component: CsmlEditBot,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
