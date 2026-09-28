import { frontendURL } from '../../../../helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/copilot'),
      component: SettingsWrapper,
      props: {
        headerTitle: 'CAPTAIN.COPILOT.TITLE',
        icon: 'i-woot-captain',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'copilot_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator'],
            featureFlag: FEATURE_FLAGS.CAPTAIN,
            installationTypes: [
              INSTALLATION_TYPES.CLOUD,
              INSTALLATION_TYPES.ENTERPRISE,
            ],
          },
        },
      ],
    },
  ],
};
