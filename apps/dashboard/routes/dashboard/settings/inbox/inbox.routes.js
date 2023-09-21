/* eslint arrow-body-style: 0 */
import SettingsContent from '../Wrapper.vue';
import Settings from './Settings.vue';
import InboxHome from './Index.vue';
import InboxChannel from './InboxChannels.vue';
import ChannelList from './ChannelList.vue';
import channelFactory from './channel-factory';
import AddAgents from './AddAgents.vue';
import FinishSetup from './FinishSetup.vue';
import { frontendURL } from '../../../../helper/URLHelper';

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
          name: 'settings_inbox',
          redirect: 'list',
        },
        {
          path: 'list',
          name: 'settings_inbox_list',
          component: InboxHome,
          roles: ['administrator'],
        },
        {
          path: 'new',
          component: InboxChannel,
          children: [
            {
              path: '',
              name: 'settings_inbox_new',
              component: ChannelList,
              roles: ['administrator'],
            },
            {
              path: ':inbox_id/finish',
              name: 'settings_inbox_finish',
              component: FinishSetup,
              roles: ['administrator'],
            },
            {
              path: ':sub_page',
              name: 'settings_inboxes_page_channel',
              component: channelFactory.create(),
              roles: ['administrator'],
              props: route => {
                return { channel_name: route.params.sub_page };
              },
            },
            {
              path: ':inbox_id/agents',
              name: 'settings_inboxes_add_agents',
              roles: ['administrator'],
              component: AddAgents,
            },
          ],
        },
        {
          path: ':inboxId',
          name: 'settings_inbox_show',
          component: Settings,
          roles: ['administrator'],
        },
      ],
    },
  ],
};
