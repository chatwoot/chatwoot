import { FEATURE_FLAGS } from '../../../../featureFlags';
import Bot from './Index.vue';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/agent-bots'),
      meta: {
        // CommMate: Allow administrators or users with settings_agent_bots_manage permission
        permissions: ['administrator', 'settings_agent_bots_manage'],
      },
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'agent_bots',
          component: Bot,
          meta: {
            featureFlag: FEATURE_FLAGS.AGENT_BOTS,
            // CommMate: Allow administrators or users with settings_agent_bots_manage permission
            permissions: ['administrator', 'settings_agent_bots_manage'],
          },
        },
      ],
    },
  ],
};
