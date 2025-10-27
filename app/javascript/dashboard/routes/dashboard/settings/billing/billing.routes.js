import { frontendURL } from '../../../../helper/URLHelper';
import { INSTALLATION_TYPES } from 'dashboard/constants/installationTypes';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';
import V2Billing from './V2Billing.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/billing'),
      meta: {
        permissions: ['administrator'],
        installationTypes: [INSTALLATION_TYPES.CLOUD],
      },
      component: SettingsWrapper,
      props: {
        headerTitle: 'BILLING_SETTINGS.TITLE',
        icon: 'credit-card-person',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'billing_settings_index',
          component: Index,
          meta: {
            installationTypes: [INSTALLATION_TYPES.CLOUD],
            permissions: ['administrator'],
          },
        },
        {
          path: 'v2',
          name: 'billing_settings_v2',
          component: V2Billing,
          meta: {
            installationTypes: [INSTALLATION_TYPES.CLOUD],
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
