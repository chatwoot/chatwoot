import { FEATURE_FLAGS } from '../../../../featureFlags';
import Bot from './Index.vue';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/agent-bots'),
      meta: {
        permissions: ['super_admin'],
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
      },
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'agent_bots',
          component: Bot,
          meta: {
            featureFlag: FEATURE_FLAGS.AGENT_BOTS,
            permissions: ['super_admin'],
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
          },
        },
      ],
    },
  ],
};
