import { frontendURL } from '../../../helper/URLHelper';
import InternalChatLayout from './InternalChatLayout.vue';
import DraftsList from './DraftsList.vue';

const INTERNAL_CHAT_PERMISSIONS = ['administrator', 'agent', 'custom_role'];

const EmptyComponent = {
  template: '<div />',
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/internal-chat'),
      name: 'internal_chat',
      meta: {
        permissions: INTERNAL_CHAT_PERMISSIONS,
        featureAccess: 'internal_chat.access',
      },
      component: InternalChatLayout,
      children: [
        {
          path: '',
          name: 'internal_chat_home',
          meta: {
            permissions: INTERNAL_CHAT_PERMISSIONS,
          },
          component: EmptyComponent,
        },
        {
          path: 'channels/:channelId',
          name: 'internal_chat_channel',
          meta: {
            permissions: INTERNAL_CHAT_PERMISSIONS,
          },
          component: EmptyComponent,
        },
        {
          path: 'channels/:channelId/thread/:messageId',
          name: 'internal_chat_thread',
          meta: {
            permissions: INTERNAL_CHAT_PERMISSIONS,
          },
          component: EmptyComponent,
        },
        {
          path: 'dm/:channelId',
          name: 'internal_chat_dm',
          meta: {
            permissions: INTERNAL_CHAT_PERMISSIONS,
          },
          component: EmptyComponent,
        },
        {
          path: 'drafts',
          name: 'internal_chat_drafts',
          meta: {
            permissions: INTERNAL_CHAT_PERMISSIONS,
          },
          component: DraftsList,
        },
      ],
    },
  ],
};
