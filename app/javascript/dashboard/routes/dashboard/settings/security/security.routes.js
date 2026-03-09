import { frontendURL } from '../../../../helper/URLHelper';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/security'),
      meta: {
        permissions: ['administrator'],
        installationTypes: [
          INSTALLATION_TYPES.CLOUD,
          INSTALLATION_TYPES.ENTERPRISE,
        ],
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'SECURITY_SETTINGS.TITLE',
        icon: 'i-lucide-shield',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'security_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator'],
            featureFlag: FEATURE_FLAGS.SAML,
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
