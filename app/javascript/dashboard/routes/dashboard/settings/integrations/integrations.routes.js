import { FEATURE_FLAGS } from '../../../../featureFlags';
  import { frontendURL } from '../../../../helper/URLHelper';
  import SettingsWrapper from '../SettingsWrapper.vue';
  import Index from './Index.vue';

  export default {
    routes: [
      {
        path: frontendURL('accounts/:accountId/settings/integrations'),
        component: SettingsWrapper,
        children: [
          {
            path: '',
            name: 'settings_integrations',
            component: Index,
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
          },
          {
            path: 'webhooks',
            name: 'settings_integrations_webhooks',
            component: () => import('./Webhooks/Index.vue'),
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
          },
          {
            path: 'slack',
            name: 'settings_integrations_slack',
            component: () => import('./Slack/Index.vue'),
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
          },
          {
            path: 'dyte',
            name: 'settings_integrations_dyte',
            component: () => import('./Dyte/Index.vue'),
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
            meta: {
              featureFlag: FEATURE_FLAGS.DYTE,
              permissions: ['administrator'],
            },
          },
          {
            path: 'openai',
            name: 'settings_integrations_openai',
            component: () => import('./OpenAI/Index.vue'),
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
            meta: {
              featureFlag: FEATURE_FLAGS.OPENAI_INTEGRATION,
              permissions: ['administrator'],
            },
          },
          {
            path: 'linear',
            name: 'settings_integrations_linear',
            component: () => import('./Linear/Index.vue'),
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
            meta: {
              featureFlag: FEATURE_FLAGS.LINEAR_INTEGRATION,
              permissions: ['administrator'],
            },
          },
          {
            path: 'captain',
            name: 'settings_integrations_captain',
            component: () => import('./Captain/Index.vue'),
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
            meta: {
              featureFlag: FEATURE_FLAGS.CAPTAIN,
              permissions: ['administrator'],
            },
          },
          {
            path: 'dashboard_apps',
            name: 'settings_integrations_dashboard_apps',
            component: () => import('./DashboardApps/Index.vue'),
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
            meta: {
              featureFlag: FEATURE_FLAGS.DASHBOARD_APPS,
              permissions: ['administrator'],
            },
          },
        ],
      },
    ],
  };
