import { frontendURL } from '../../../../helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';
import McpServersIndex from './mcpServers/Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/captain'),
      meta: {
        permissions: ['administrator'],
        featureFlag: FEATURE_FLAGS.CAPTAIN,
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'CAPTAIN_SETTINGS.TITLE',
        icon: 'i-lucide-bot',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'captain_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator'],
            featureFlag: FEATURE_FLAGS.CAPTAIN,
            installationTypes: [
              INSTALLATION_TYPES.ENTERPRISE,
              INSTALLATION_TYPES.CLOUD,
            ],
          },
        },
        {
          path: 'mcp-servers',
          name: 'captain_settings_mcp_servers',
          component: McpServersIndex,
          meta: {
            permissions: ['administrator'],
            featureFlag: FEATURE_FLAGS.CAPTAIN_MCP,
            installationTypes: [
              INSTALLATION_TYPES.ENTERPRISE,
              INSTALLATION_TYPES.CLOUD,
            ],
          },
        },
      ],
    },
  ],
};
