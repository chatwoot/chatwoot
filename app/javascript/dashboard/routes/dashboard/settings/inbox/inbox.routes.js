/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../../helper/URLHelper';
import channelFactory from './channel-factory';

const SettingsContent = () => import('../Wrapper.vue');
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
          path: '',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'settings_inbox_list',
          component: InboxHome,
          meta: {
            permissions: ['administrator'],
          },
        },
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
              component: channelFactory.create(),
              meta: {
                permissions: ['administrator'],
              },
              props: route => {
                return { channel_name: route.params.sub_page };
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
