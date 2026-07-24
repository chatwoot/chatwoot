import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import BusinessRulesIndex from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/business-rules'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'business_rules_index',
          component: BusinessRulesIndex,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
