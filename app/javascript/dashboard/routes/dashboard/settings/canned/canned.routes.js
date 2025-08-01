import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import CannedHome from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/canned-response'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'canned_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'canned_list',
          meta: {
            featureFlag: FEATURE_FLAGS.CANNED_RESPONSES,
            permissions: ['administrator', 'agent', 'custom_role'],
          },
          component: CannedHome,
        },
      ],
    },
  ],
};
