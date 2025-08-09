  import { FEATURE_FLAGS } from '../../../../featureFlags';
  import { frontendURL } from '../../../../helper/URLHelper';
  import SettingsWrapper from '../SettingsWrapper.vue';
  import Bot from './Index.vue';

  export default {
    routes: [
      {
        path: frontendURL('accounts/:accountId/settings/agent-bots'),
        beforeEnter: (to, from, next) => {
          const user = store.getters.getCurrentUser;
          if (user?.type === 'SuperAdmin') {
            next();
          } else {
            next({ name: 'settings_home' });
          }
        },
        meta: {
          permissions: ['administrator'],
        },
        component: SettingsWrapper,
        children: [
          {
            path: '',
            name: 'agent_bots',
            component: Bot,
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
            meta: {
              featureFlag: FEATURE_FLAGS.AGENT_BOTS,
              permissions: ['administrator'],
            },
          },
        ],
      },
    ],
  };
