import { FEATURE_FLAGS } from '../../../../featureFlags';
  import { frontendURL } from '../../../../helper/URLHelper';
  import SettingsWrapper from '../SettingsWrapper.vue';
  import Index from './Index.vue';

  export default {
    routes: [
      {
        path: frontendURL('accounts/:accountId/settings/inboxes'),
        component: SettingsWrapper,
        children: [
          {
            path: '',
            name: 'settings_inbox_list',
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
            path: 'new',
            name: 'settings_inboxes_new',
            component: () => import('./channels/Index.vue'),
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
            path: ':inboxId',
            name: 'settings_inboxes_show',
            component: () => import('./Settings/Index.vue'),
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
            path: ':inboxId/campaigns',
            name: 'settings_inbox_campaigns',
            component: () => import('./campaigns/Index.vue'),
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
            meta: {
              featureFlag: FEATURE_FLAGS.CAMPAIGNS,
              permissions: ['administrator'],
            },
          },
          {
            path: ':inboxId/campaigns/new',
            name: 'settings_inbox_campaigns_new',
            component: () => import('./campaigns/AddCampaign.vue'),
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
            meta: {
              featureFlag: FEATURE_FLAGS.CAMPAIGNS,
              permissions: ['administrator'],
            },
          },
          {
            path: ':inboxId/campaigns/:campaignId/edit',
            name: 'settings_inbox_campaigns_edit',
            component: () => import('./campaigns/EditCampaign.vue'),
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
            meta: {
              featureFlag: FEATURE_FLAGS.CAMPAIGNS,
              permissions: ['administrator'],
            },
          },
        ],
      },
    ],
  };
