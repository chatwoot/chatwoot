import { frontendURL } from '../../../../helper/URLHelper';
import ChannelFactory from './ChannelFactory.vue';

const SettingsContent = () => import('../Wrapper.vue');
const SettingWrapper = () => import('../SettingsWrapper.vue');
const InboxHome = () => import('./Index.vue');
const Settings = () => import('./Settings.vue');
const InboxChannel = () => import('./InboxChannels.vue');
const ChannelList = () => import('./ChannelList.vue');
const AddAgents = () => import('./AddAgents.vue');
const FinishSetup = () => import('./FinishSetup.vue');

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
          meta: {
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
        return {
          headerTitle: 'INBOX_MGMT.HEADER',
          headerButtonText: 'SETTINGS.INBOXES.NEW_INBOX',
          icon: 'mail-inbox-all',
          newButtonRoutes: ['settings_inbox_list'],
          showBackButton,
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
              meta: {
                permissions: ['administrator'],
              },
            },
            {
              path: ':inbox_id/finish',
              name: 'settings_inbox_finish',
              component: FinishSetup,
              meta: {
                permissions: ['administrator'],
              },
            },
            {
              path: ':sub_page',
              name: 'settings_inboxes_page_channel',
              component: ChannelFactory,
              meta: {
                permissions: ['administrator'],
              },
              props: route => {
                return { channelName: route.params.sub_page };
              },
            },
            {
              path: ':inbox_id/agents',
              name: 'settings_inboxes_add_agents',
              meta: {
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
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
