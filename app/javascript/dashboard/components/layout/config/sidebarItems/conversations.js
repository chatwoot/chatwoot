import { frontendURL } from '../../../../helper/URLHelper';

const conversations = accountId => ({
  parentNav: 'conversations',
  routes: [
    'home',
    'inbox_dashboard',
    'inbox_conversation',
    'conversation_through_inbox',
    'notifications_dashboard',
    'label_conversations',
    'conversations_through_label',
    'team_conversations',
    'conversations_through_team',
    'conversation_mentions',
    'conversation_through_mentions',
    'conversation_participating',
    'conversation_through_participating',
    'folder_conversations',
    'conversations_through_folders',
    'conversation_unattended',
    'conversation_through_unattended',
    'conversation_recently_resolved'
  ],
  menuItems: [
    {
      icon: 'chat',
      label: 'ALL_CONVERSATIONS',
      key: 'conversations',
      toState: frontendURL(`accounts/${accountId}/dashboard`),
      toolTip: 'Conversation from all subscribed inboxes',
      toStateName: 'home',
    },
    {
      icon: 'mention',
      label: 'MENTIONED_CONVERSATIONS',
      key: 'conversation_mentions',
      toState: frontendURL(`accounts/${accountId}/mentions/conversations`),
      toStateName: 'conversation_mentions',
    },
    {
      icon: 'mail-unread',
      label: 'UNATTENDED_CONVERSATIONS',
      key: 'conversation_unattended',
      toState: frontendURL(`accounts/${accountId}/unattended/conversations`),
      toStateName: 'conversation_unattended',
    },
    {
      icon: 'checkmark-circle',
      label: 'RECENTLY_RESOLVED',
      key: 'conversation_recently_resolved',
      toState: frontendURL(`accounts/${accountId}/recently_resolved/conversations`),
      toStateName: 'conversation_recently_resolved',
    }
  ],
});

export default conversations;
