import { frontendURL } from '../../../../helper/URLHelper';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

const meta = {
  permissions: ['administrator'],
  featureFlag: FEATURE_FLAGS.CAPTAIN,
  installationTypes: [INSTALLATION_TYPES.ENTERPRISE, INSTALLATION_TYPES.CLOUD],
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/copilot'),
      meta,
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'copilot_settings_index',
          component: Index,
          meta,
        },
      ],
    },
  ],
};
