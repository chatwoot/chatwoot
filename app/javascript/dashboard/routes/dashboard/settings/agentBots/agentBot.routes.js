import SettingsContent from '../Wrapper';
const Bot = () => import('./Index.vue');
const CsmlEditBot = () => import('./csml/Edit.vue');
const CsmlNewBot = () => import('./csml/New.vue');
import { frontendURL } from '../../../../helper/URLHelper';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/agent-bots'),
      roles: ['administrator'],
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
          roles: ['administrator'],
        },
        {
          path: 'csml/new',
          name: 'agent_bots_csml_new',
          component: CsmlNewBot,
          roles: ['administrator'],
        },
        {
          path: 'csml/:botId',
          name: 'agent_bots_csml_edit',
          component: CsmlEditBot,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
