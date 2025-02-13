import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';

import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/sla'),
      component: SettingsWrapper,
      props: {},
      children: [
        {
          path: '',
          name: 'sla_wrapper',
          meta: {
            featureFlag: FEATURE_FLAGS.SLA,
            permissions: ['administrator'],
          },
          redirect: to => {
            return { name: 'sla_list', params: to.params };
          },
        },
        {
          path: 'list',
          name: 'sla_list',
          meta: {
            featureFlag: FEATURE_FLAGS.SLA,
            permissions: ['administrator'],
          },
          component: Index,
        },
      ],
    },
  ],
};
