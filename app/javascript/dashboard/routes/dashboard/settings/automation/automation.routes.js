import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import Automation from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/automation'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'automation_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'automation_list',
          component: Automation,
          meta: {
            // CUSTOMIZAÇÃO_SYNAPSEOS: Automations nativas escondidas até o motor próprio ficar pronto.
            featureFlag: FEATURE_FLAGS.SYNAPSEOS_AUTOMATIONS_NATIVE,
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
