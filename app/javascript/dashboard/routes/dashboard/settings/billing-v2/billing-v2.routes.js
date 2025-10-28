import { frontendURL } from '../../../../helper/URLHelper';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import SettingsWrapper from '../SettingsWrapper.vue';
import IndexV2 from './IndexV2.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/billing-v2'),
      meta: {
        permissions: ['administrator'],
        installationTypes: [INSTALLATION_TYPES.CLOUD],
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'BILLING_SETTINGS_V2.TITLE',
        icon: 'credit-card-person',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'billing_settings_v2_index',
          component: IndexV2,
          meta: {
            installationTypes: [INSTALLATION_TYPES.CLOUD],
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
