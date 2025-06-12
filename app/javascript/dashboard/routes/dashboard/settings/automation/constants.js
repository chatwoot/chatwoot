import {
  OPERATOR_TYPES_1,
  OPERATOR_TYPES_2,
  OPERATOR_TYPES_3,
  OPERATOR_TYPES_6,
} from './operators';

export const AUTOMATIONS = {
  message_created: {
    conditions: [
      {
        key: 'message_type',
        name: 'MESSAGE_TYPE',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'content',
        name: 'MESSAGE_CONTAINS',
        inputType: 'comma_separated_plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'email',
        name: 'EMAIL',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'inbox_id',
        name: 'INBOX',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'conversation_language',
        name: 'CONVERSATION_LANGUAGE',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'phone_number',
        name: 'PHONE_NUMBER',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_6,
      },
    ],
    actions: [
      {
        key: 'assign_agent',
        name: 'ASSIGN_AGENT',
      },
      {
        key: 'assign_team',
        name: 'ASSIGN_TEAM',
      },
      {
        key: 'add_label',
        name: 'ADD_LABEL',
      },
      {
        key: 'remove_label',
        name: 'REMOVE_LABEL',
      },
      {
        key: 'send_email_to_team',
        name: 'SEND_EMAIL_TO_TEAM',
      },
      {
        key: 'send_message',
        name: 'SEND_MESSAGE',
      },
      {
        key: 'send_email_transcript',
        name: 'SEND_EMAIL_TRANSCRIPT',
      },
      {
        key: 'mute_conversation',
        name: 'MUTE_CONVERSATION',
      },
      {
        key: 'snooze_conversation',
        name: 'SNOOZE_CONVERSATION',
      },

      {
        key: 'resolve_conversation',
        name: 'RESOLVE_CONVERSATION',
      },
      {
        key: 'send_webhook_event',
        name: 'SEND_WEBHOOK_EVENT',
      },
      {
        key: 'send_attachment',
        name: 'SEND_ATTACHMENT',
      },
    ],
  },
  conversation_created: {
    conditions: [
      {
        key: 'status',
        name: 'STATUS',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'browser_language',
        name: 'BROWSER_LANGUAGE',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'mail_subject',
        name: 'MAIL_SUBJECT',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'country_code',
        name: 'COUNTRY_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'phone_number',
        name: 'PHONE_NUMBER',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_6,
      },
      {
        key: 'referer',
        name: 'REFERER_LINK',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'email',
        name: 'EMAIL',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'inbox_id',
        name: 'INBOX',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'conversation_language',
        name: 'CONVERSATION_LANGUAGE',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'priority',
        name: 'PRIORITY',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
    ],
    actions: [
      {
        key: 'assign_agent',
        name: 'ASSIGN_AGENT',
      },
      {
        key: 'assign_team',
        name: 'ASSIGN_TEAM',
      },
      {
        key: 'assign_agent',
        name: 'ASSIGN_AGENT',
      },
      {
        key: 'send_email_to_team',
        name: 'SEND_EMAIL_TO_TEAM',
      },
      {
        key: 'send_message',
        name: 'SEND_MESSAGE',
      },
      {
        key: 'send_email_transcript',
        name: 'SEND_EMAIL_TRANSCRIPT',
      },
      {
        key: 'mute_conversation',
        name: 'MUTE_CONVERSATION',
      },
      {
        key: 'snooze_conversation',
        name: 'SNOOZE_CONVERSATION',
      },
      {
        key: 'resolve_conversation',
        name: 'RESOLVE_CONVERSATION',
      },
      {
        key: 'send_webhook_event',
        name: 'SEND_WEBHOOK_EVENT',
      },
      {
        key: 'send_attachment',
        name: 'SEND_ATTACHMENT',
      },
    ],
  },
  conversation_updated: {
    conditions: [
      {
        key: 'status',
        name: 'STATUS',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'browser_language',
        name: 'BROWSER_LANGUAGE',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'mail_subject',
        name: 'MAIL_SUBJECT',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'country_code',
        name: 'COUNTRY_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'referer',
        name: 'REFERER_LINK',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'phone_number',
        name: 'PHONE_NUMBER',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_6,
      },
      {
        key: 'assignee_id',
        name: 'ASSIGNEE_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'team_id',
        name: 'TEAM_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'email',
        name: 'EMAIL',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'inbox_id',
        name: 'INBOX',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'conversation_language',
        name: 'CONVERSATION_LANGUAGE',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'priority',
        name: 'PRIORITY',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
    ],
    actions: [
      {
        key: 'assign_agent',
        name: 'ASSIGN_AGENT',
      },
      {
        key: 'assign_team',
        name: 'ASSIGN_TEAM',
      },
      {
        key: 'assign_agent',
        name: 'ASSIGN_AGENT',
      },
      {
        key: 'send_email_to_team',
        name: 'SEND_EMAIL_TO_TEAM',
      },
      {
        key: 'send_message',
        name: 'SEND_MESSAGE',
      },
      {
        key: 'send_email_transcript',
        name: 'SEND_EMAIL_TRANSCRIPT',
      },
      {
        key: 'mute_conversation',
        name: 'MUTE_CONVERSATION',
      },
      {
        key: 'snooze_conversation',
        name: 'SNOOZE_CONVERSATION',
      },
      {
        key: 'resolve_conversation',
        name: 'RESOLVE_CONVERSATION',
      },
      {
        key: 'send_webhook_event',
        name: 'SEND_WEBHOOK_EVENT',
      },
      {
        key: 'send_attachment',
        name: 'SEND_ATTACHMENT',
      },
    ],
  },
  conversation_opened: {
    conditions: [
      {
        key: 'browser_language',
        name: 'BROWSER_LANGUAGE',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'email',
        name: 'EMAIL',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'mail_subject',
        name: 'MAIL_SUBJECT',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'country_code',
        name: 'COUNTRY_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'referer',
        name: 'REFERER_LINK',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'assignee_id',
        name: 'ASSIGNEE_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'phone_number',
        name: 'PHONE_NUMBER',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_6,
      },
      {
        key: 'team_id',
        name: 'TEAM_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'inbox_id',
        name: 'INBOX',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'conversation_language',
        name: 'CONVERSATION_LANGUAGE',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'priority',
        name: 'PRIORITY',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
    ],
    actions: [
      {
        key: 'assign_agent',
        name: 'ASSIGN_AGENT',
      },
      {
        key: 'assign_team',
        name: 'ASSIGN_TEAM',
      },
      {
        key: 'assign_agent',
        name: 'ASSIGN_AGENT',
      },
      {
        key: 'send_email_to_team',
        name: 'SEND_EMAIL_TO_TEAM',
      },
      {
        key: 'send_message',
        name: 'SEND_MESSAGE',
      },
      {
        key: 'send_email_transcript',
        name: 'SEND_EMAIL_TRANSCRIPT',
      },
      {
        key: 'mute_conversation',
        name: 'MUTE_CONVERSATION',
      },
      {
        key: 'snooze_conversation',
        name: 'SNOOZE_CONVERSATION',
      },
      {
        key: 'send_webhook_event',
        name: 'SEND_WEBHOOK_EVENT',
      },
      {
        key: 'send_attachment',
        name: 'SEND_ATTACHMENT',
      },
    ],
  },
  conversation_resolved: {
    conditions: [
      {
        key: 'browser_language',
        name: 'Browser Language',
        attributeI18nKey: 'BROWSER_LANGUAGE',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'email',
        name: 'Email',
        attributeI18nKey: 'EMAIL',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'mail_subject',
        name: 'Email Subject',
        attributeI18nKey: 'MAIL_SUBJECT',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'country_code',
        name: 'Country',
        attributeI18nKey: 'COUNTRY_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'referer',
        name: 'Referrer Link',
        attributeI18nKey: 'REFERER_LINK',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'assignee_id',
        name: 'Assignee',
        attributeI18nKey: 'ASSIGNEE_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'phone_number',
        name: 'Phone Number',
        attributeI18nKey: 'PHONE_NUMBER',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_6,
      },
      {
        key: 'team_id',
        name: 'Team',
        attributeI18nKey: 'TEAM_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'inbox_id',
        name: 'Inbox',
        attributeI18nKey: 'INBOX',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'conversation_language',
        name: 'Conversation Language',
        attributeI18nKey: 'CONVERSATION_LANGUAGE',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'priority',
        name: 'Priority',
        attributeI18nKey: 'PRIORITY',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
    ],
    actions: [
      {
        key: 'assign_agent',
        name: 'Assign to agent',
        attributeI18nKey: 'ASSIGN_AGENT',
      },
      {
        key: 'assign_team',
        name: 'Assign a team',
        attributeI18nKey: 'ASSIGN_TEAM',
      },
      {
        key: 'send_email_to_team',
        name: 'Send an email to team',
        attributeI18nKey: 'SEND_EMAIL_TO_TEAM',
      },
      {
        key: 'send_message',
        name: 'Send a message',
        attributeI18nKey: 'SEND_MESSAGE',
      },
      {
        key: 'send_email_transcript',
        name: 'Send an email transcript',
        attributeI18nKey: 'SEND_EMAIL_TRANSCRIPT',
      },
      {
        key: 'send_webhook_event',
        name: 'Send Webhook Event',
        attributeI18nKey: 'SEND_WEBHOOK_EVENT',
      },
      {
        key: 'send_attachment',
        name: 'Send Attachment',
        attributeI18nKey: 'SEND_ATTACHMENT',
      },
    ],
  },
};

export const AUTOMATION_RULE_EVENTS = [
  {
    key: 'conversation_created',
    value: 'CONVERSATION_CREATED',
  },
  {
    key: 'conversation_updated',
    value: 'CONVERSATION_UPDATED',
  },
  {
    key: 'conversation_resolved',
    value: 'Conversation Resolved',
  },
  {
    key: 'message_created',
    value: 'MESSAGE_CREATED',
  },
  {
    key: 'conversation_opened',
    value: 'CONVERSATION_OPENED',
  },
];

export const AUTOMATION_ACTION_TYPES = [
  {
    key: 'assign_agent',
    label: 'ASSIGN_AGENT',
    inputType: 'search_select',
  },
  {
    key: 'assign_team',
    label: 'ASSIGN_TEAM',
    inputType: 'search_select',
  },
  {
    key: 'add_label',
    label: 'ADD_LABEL',
    inputType: 'multi_select',
  },
  {
    key: 'remove_label',
    label: 'REMOVE_LABEL',
    inputType: 'multi_select',
  },
  {
    key: 'send_email_to_team',
    label: 'SEND_EMAIL_TO_TEAM',
    inputType: 'team_message',
  },
  {
    key: 'send_email_transcript',
    label: 'SEND_EMAIL_TRANSCRIPT',
    inputType: 'email',
  },
  {
    key: 'mute_conversation',
    label: 'MUTE_CONVERSATION',
    inputType: null,
  },
  {
    key: 'snooze_conversation',
    label: 'SNOOZE_CONVERSATION',
    inputType: null,
  },
  {
    key: 'resolve_conversation',
    label: 'RESOLVE_CONVERSATION',
    inputType: null,
  },
  {
    key: 'send_webhook_event',
    label: 'SEND_WEBHOOK_EVENT',
    inputType: 'url',
  },
  {
    key: 'send_attachment',
    label: 'SEND_ATTACHMENT',
    inputType: 'attachment',
  },
  {
    key: 'send_message',
    label: 'SEND_MESSAGE',
    inputType: 'textarea',
  },
  {
    key: 'change_priority',
    label: 'CHANGE_PRIORITY',
    inputType: 'search_select',
  },
  {
    key: 'add_sla',
    label: 'ADD_SLA',
    inputType: 'search_select',
  },
];
