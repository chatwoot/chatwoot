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
    'conversation_calling_nudges',
    'conversation_through_calling_nudges',
    'conversation_missed_calls',
    'conversation_through_missed_calls',
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
      icon: 'call-outbound',
      label: 'CALLING_NUDGES',
      key: 'conversation_calling_nudges',
      toState: frontendURL(
        `accounts/${accountId}/calling_nudges/conversations`
      ),
      toStateName: 'conversation_calling_nudges',
    },
    {
      icon: 'call-missed',
      label: 'MISSED_CALLS',
      key: 'conversation_missed_calls',
      toState: frontendURL(`accounts/${accountId}/missed_calls/conversations`),
      toStateName: 'conversation_missed_calls',
    },
  ],
});

export default conversations;
