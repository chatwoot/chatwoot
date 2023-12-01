/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../helper/URLHelper';
const ConversationView = () => import('./ConversationView');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/dashboard'),
      name: 'home',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: () => {
        return { inboxId: 0 };
      },
    },
    {
      path: frontendURL('accounts/:accountId/conversations/:conversation_id'),
      name: 'inbox_conversation',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => {
        return { inboxId: 0, conversationId: route.params.conversation_id };
      },
    },
    {
      path: frontendURL('accounts/:accountId/inbox/:inbox_id'),
      name: 'inbox_dashboard',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => {
        return { inboxId: route.params.inbox_id };
      },
    },
    {
      path: frontendURL(
        'accounts/:accountId/inbox/:inbox_id/conversations/:conversation_id'
      ),
      name: 'conversation_through_inbox',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => {
        return {
          conversationId: route.params.conversation_id,
          inboxId: route.params.inbox_id,
        };
      },
    },
    {
      path: frontendURL('accounts/:accountId/label/:label'),
      name: 'label_conversations',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => ({ label: route.params.label }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/label/:label/conversations/:conversation_id'
      ),
      name: 'conversations_through_label',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversation_id,
        label: route.params.label,
      }),
    },
    {
      path: frontendURL('accounts/:accountId/team/:teamId'),
      name: 'team_conversations',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => ({ teamId: route.params.teamId }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/team/:teamId/conversations/:conversationId'
      ),
      name: 'conversations_through_team',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        teamId: route.params.teamId,
      }),
    },
    {
      path: frontendURL('accounts/:accountId/custom_view/:id'),
      name: 'folder_conversations',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => ({ foldersId: route.params.id }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/custom_view/:id/conversations/:conversation_id'
      ),
      name: 'conversations_through_folders',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversation_id,
        foldersId: route.params.id,
      }),
    },
    {
      path: frontendURL('accounts/:accountId/mentions/conversations'),
      name: 'conversation_mentions',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: () => ({ conversationType: 'mention' }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/mentions/conversations/:conversationId'
      ),
      name: 'conversation_through_mentions',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        conversationType: 'mention',
      }),
    },
    {
      path: frontendURL('accounts/:accountId/unattended/conversations'),
      name: 'conversation_unattended',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: () => ({ conversationType: 'unattended' }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/unattended/conversations/:conversationId'
      ),
      name: 'conversation_through_unattended',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        conversationType: 'unattended',
      }),
    },
    {
      path: frontendURL('accounts/:accountId/participating/conversations'),
      name: 'conversation_participating',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: () => ({ conversationType: 'participating' }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/participating/conversations/:conversationId'
      ),
      name: 'conversation_through_participating',
      roles: ['administrator', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        conversationType: 'participating',
      }),
    },
  ],
};
