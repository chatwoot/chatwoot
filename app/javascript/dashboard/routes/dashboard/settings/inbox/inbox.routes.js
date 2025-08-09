  import { FEATURE_FLAGS } from '../../../../featureFlags';
  import { frontendURL } from '../../../../helper/URLHelper';
  import ChannelFactory from './ChannelFactory.vue';

  import SettingsContent from '../Wrapper.vue';
  import SettingWrapper from '../SettingsWrapper.vue';
  import InboxHome from './Index.vue';
  import Settings from './Settings.vue';
  import InboxChannel from './InboxChannels.vue';
  import ChannelList from './ChannelList.vue';
  import AddAgents from './AddAgents.vue';
  import FinishSetup from './FinishSetup.vue';

  export default {
    routes: [
      {
        path: frontendURL('accounts/:accountId/settings/inboxes'),
        component: SettingWrapper,
        children: [
          {
            path: '',
            redirect: to => {
              return { name: 'settings_inbox_list', params: to.params };
            },
          },
          {
            path: 'list',
            name: 'settings_inbox_list',
            component: InboxHome,
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
            meta: {
              featureFlag: FEATURE_FLAGS.INBOX_MANAGEMENT,
              permissions: ['administrator'],
            },
          },
        ],
      },
      {
        path: frontendURL('accounts/:accountId/settings/inboxes'),
        component: SettingsContent,
        props: params => {
          const showBackButton = params.name !== 'settings_inbox_list';
          const fullWidth = params.name === 'settings_inbox_show';
          return {
            headerTitle: 'INBOX_MGMT.HEADER',
            icon: 'mail-inbox-all',
            showBackButton,
            fullWidth,
          };
        },
        children: [
          {
            path: 'new',
            component: InboxChannel,
            children: [
              {
                path: '',
                name: 'settings_inbox_new',
                component: ChannelList,
                beforeEnter: (to, from, next) => {
                  const user = store.getters.getCurrentUser;
                  if (user?.type === 'SuperAdmin') {
                    next();
                  } else {
                    next({ name: 'settings_home' });
                  }
                },
                meta: {
                  featureFlag: FEATURE_FLAGS.INBOX_MANAGEMENT,
                  permissions: ['administrator'],
                },
              },
              {
                path: ':inbox_id/finish',
                name: 'settings_inbox_finish',
                component: FinishSetup,
                beforeEnter: (to, from, next) => {
                  const user = store.getters.getCurrentUser;
                  if (user?.type === 'SuperAdmin') {
                    next();
                  } else {
                    next({ name: 'settings_home' });
                  }
                },
                meta: {
                  featureFlag: FEATURE_FLAGS.INBOX_MANAGEMENT,
                  permissions: ['administrator'],
                },
              },
              {
                path: ':sub_page',
                name: 'settings_inboxes_page_channel',
                component: ChannelFactory,
                beforeEnter: (to, from, next) => {
                  const user = store.getters.getCurrentUser;
                  if (user?.type === 'SuperAdmin') {
                    next();
                  } else {
                    next({ name: 'settings_home' });
                  }
                },
                meta: {
                  featureFlag: FEATURE_FLAGS.INBOX_MANAGEMENT,
                  permissions: ['administrator'],
                },
                props: route => {
                  return { channelName: route.params.sub_page };
                },
              },
              {
                path: ':inbox_id/agents',
                name: 'settings_inboxes_add_agents',
                beforeEnter: (to, from, next) => {
                  const user = store.getters.getCurrentUser;
                  if (user?.type === 'SuperAdmin') {
                    next();
                  } else {
                    next({ name: 'settings_home' });
                  }
                },
                meta: {
                  featureFlag: FEATURE_FLAGS.INBOX_MANAGEMENT,
                  permissions: ['administrator'],
                },
                component: AddAgents,
              },
            ],
          },
          {
            path: ':inboxId',
            name: 'settings_inbox_show',
            component: Settings,
            beforeEnter: (to, from, next) => {
              const user = store.getters.getCurrentUser;
              if (user?.type === 'SuperAdmin') {
                next();
              } else {
                next({ name: 'settings_home' });
              }
            },
            meta: {
              featureFlag: FEATURE_FLAGS.INBOX_MANAGEMENT,
              permissions: ['administrator'],
            },
          },
        ],
      },
    ],
  };
