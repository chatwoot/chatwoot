/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../helper/URLHelper';
const ConversationView = () => import('./ConversationView');

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/dashboard'),
      name: 'home',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: () => {
        return { inboxId: 0 };
      },
    },
    {
      path: frontendURL('accounts/:accountId/conversations/:conversation_id'),
      name: 'inbox_conversation',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => {
        return { inboxId: 0, conversationId: route.params.conversation_id };
      },
    },
    {
      path: frontendURL('accounts/:accountId/inbox/:inbox_id'),
      name: 'inbox_dashboard',
      roles: ['administrator', 'leader', 'agent'],
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
      roles: ['administrator', 'leader', 'agent'],
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
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({ label: route.params.label }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/label/:label/conversations/:conversation_id'
      ),
      name: 'conversations_through_label',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversation_id,
        label: route.params.label,
      }),
    },
    {
      path: frontendURL('accounts/:accountId/team/:teamId'),
      name: 'team_conversations',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({ teamId: route.params.teamId }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/team/:teamId/conversations/:conversationId'
      ),
      name: 'conversations_through_team',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        teamId: route.params.teamId,
      }),
    },
    {
      path: frontendURL('accounts/:accountId/custom_view/:id'),
      name: 'folder_conversations',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({ foldersId: route.params.id }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/custom_view/:id/conversations/:conversation_id'
      ),
      name: 'conversations_through_folders',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversation_id,
        foldersId: route.params.id,
      }),
    },
    {
      path: frontendURL('accounts/:accountId/mentions/conversations'),
      name: 'conversation_mentions',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: () => ({ conversationType: 'mention' }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/mentions/conversations/:conversationId'
      ),
      name: 'conversation_through_mentions',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        conversationType: 'mention',
      }),
    },
    {
      path: frontendURL('accounts/:accountId/unattended/conversations'),
      name: 'conversation_unattended',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: () => ({ conversationType: 'unattended' }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/unattended/conversations/:conversationId'
      ),
      name: 'conversation_through_unattended',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        conversationType: 'unattended',
      }),
    },
    {
      path: frontendURL('accounts/:accountId/unread/conversations'),
      name: 'conversation_unread',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: () => ({ conversationType: 'unread' }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/unread/conversations/:conversationId'
      ),
      name: 'conversation_through_unread',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        conversationType: 'unread',
      }),
    },
    {
      path: frontendURL('accounts/:accountId/open/conversations'),
      name: 'conversation_open_status',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: () => ({ status: 'open' }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/open/conversations/:conversationId'
      ),
      name: 'conversation_through_open_status',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        status: 'open',
      }),
    },
    {
      path: frontendURL('accounts/:accountId/pending/conversations'),
      name: 'conversation_pending_status',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: () => ({ status: 'pending' }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/pending/conversations/:conversationId'
      ),
      name: 'conversation_through_pending_status',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        status: 'pending',
      }),
    },
    {
      path: frontendURL('accounts/:accountId/snoozed/conversations'),
      name: 'conversation_snoozed_status',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: () => ({ status: 'snoozed' }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/snoozed/conversations/:conversationId'
      ),
      name: 'conversation_through_snoozed_status',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        status: 'snoozed',
      }),
    },
    {
      path: frontendURL('accounts/:accountId/resolved/conversations'),
      name: 'conversation_resolved_status',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: () => ({ status: 'resolved' }),
    },
    {
      path: frontendURL(
        'accounts/:accountId/resolved/conversations/:conversationId'
      ),
      name: 'conversation_through_resolved_status',
      roles: ['administrator', 'leader', 'agent'],
      component: ConversationView,
      props: route => ({
        conversationId: route.params.conversationId,
        status: 'resolved',
      }),
    },
  ],
};
