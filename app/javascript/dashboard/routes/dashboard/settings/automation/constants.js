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
        name: 'Message Type',
        attributeI18nKey: 'MESSAGE_TYPE',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'content',
        name: 'Message Content',
        attributeI18nKey: 'MESSAGE_CONTAINS',
        inputType: 'comma_separated_plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'email',
        name: 'Email',
        attributeI18nKey: 'EMAIL',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
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
        key: 'phone_number',
        name: 'Phone Number',
        attributeI18nKey: 'PHONE_NUMBER',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_6,
      },
      {
        key: 'contact_label',
        name: 'Contact Label',
        attributeI18nKey: 'CONTACT_LABEL',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'conversation_label',
        name: 'Conversation Label',
        attributeI18nKey: 'PRIORITY',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
    ],
    actions: [
      {
        key: 'assign_agent',
        label: 'Assign to agent',
        inputType: 'search_select',
      },
      {
        key: 'assign_team',
        label: 'Assign a team',
        inputType: 'search_select',
      },
      {
        key: 'add_label',
        label: 'Add conversation label',
        inputType: 'multi_select',
      },
      {
        key: 'remove_label',
        label: 'Remove conversation label',
        inputType: 'multi_select',
      },
      {
        key: 'add_contact_label',
        label: 'Add contact label',
        inputType: 'multi_select',
      },
      {
        key: 'remove_contact_label',
        label: 'Remove contact label',
        inputType: 'multi_select',
      },
      {
        key: 'send_email_to_team',
        label: 'Send an email to team',
        inputType: 'team_message',
      },
      {
        key: 'send_email_transcript',
        label: 'Send an email transcript',
        inputType: 'email',
      },
      {
        key: 'mute_conversation',
        label: 'Mute conversation',
        inputType: null,
      },
      {
        key: 'snooze_conversation',
        label: 'Snooze conversation',
        inputType: null,
      },
      {
        key: 'resolve_conversation',
        label: 'Resolve conversation',
        inputType: null,
      },
      {
        key: 'send_webhook_event',
        label: 'Send Webhook Event',
        inputType: 'url',
      },
      {
        key: 'send_attachment',
        label: 'Send Attachment',
        inputType: 'attachment',
      },
      {
        key: 'send_message',
        label: 'Send a message',
        inputType: 'textarea',
      },
      {
        key: 'send_template',
        label: 'Send a template',
        inputType: 'template',
      },
      {
        key: 'change_priority',
        label: 'Change Priority',
        inputType: 'search_select',
      },
      {
        key: 'add_sla',
        label: 'Add SLA',
        inputType: 'search_select',
      },
    ],
  },
  conversation_created: {
    conditions: [
      {
        key: 'status',
        name: 'Status',
        attributeI18nKey: 'STATUS',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'browser_language',
        name: 'Browser Language',
        attributeI18nKey: 'BROWSER_LANGUAGE',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
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
        key: 'phone_number',
        name: 'Phone Number',
        attributeI18nKey: 'PHONE_NUMBER',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_6,
      },
      {
        key: 'referer',
        name: 'Referrer Link',
        attributeI18nKey: 'REFERER_LINK',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'email',
        name: 'Email',
        attributeI18nKey: 'EMAIL',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
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
      {
        key: 'contact_label',
        name: 'Contact Label',
        attributeI18nKey: 'CONTACT_LABEL',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'conversation_label',
        name: 'Conversation Label',
        attributeI18nKey: 'PRIORITY',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
    ],
    actions: [
      {
        key: 'assign_agent',
        label: 'Assign to agent',
        inputType: 'search_select',
      },
      {
        key: 'assign_team',
        label: 'Assign a team',
        inputType: 'search_select',
      },
      {
        key: 'add_label',
        label: 'Add conversation label',
        inputType: 'multi_select',
      },
      {
        key: 'remove_label',
        label: 'Remove conversation label',
        inputType: 'multi_select',
      },
      {
        key: 'add_contact_label',
        label: 'Add contact label',
        inputType: 'multi_select',
      },
      {
        key: 'remove_contact_label',
        label: 'Remove contact label',
        inputType: 'multi_select',
      },
      {
        key: 'send_email_to_team',
        label: 'Send an email to team',
        inputType: 'team_message',
      },
      {
        key: 'send_email_transcript',
        label: 'Send an email transcript',
        inputType: 'email',
      },
      {
        key: 'mute_conversation',
        label: 'Mute conversation',
        inputType: null,
      },
      {
        key: 'snooze_conversation',
        label: 'Snooze conversation',
        inputType: null,
      },
      {
        key: 'resolve_conversation',
        label: 'Resolve conversation',
        inputType: null,
      },
      {
        key: 'send_webhook_event',
        label: 'Send Webhook Event',
        inputType: 'url',
      },
      {
        key: 'send_attachment',
        label: 'Send Attachment',
        inputType: 'attachment',
      },
      {
        key: 'send_message',
        label: 'Send a message',
        inputType: 'textarea',
      },
      {
        key: 'send_template',
        label: 'Send a template',
        inputType: 'template',
      },
      {
        key: 'change_priority',
        label: 'Change Priority',
        inputType: 'search_select',
      },
      {
        key: 'add_sla',
        label: 'Add SLA',
        inputType: 'search_select',
      },
    ],
  },
  conversation_updated: {
    conditions: [
      {
        key: 'status',
        name: 'Status',
        attributeI18nKey: 'STATUS',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'browser_language',
        name: 'Browser Language',
        attributeI18nKey: 'BROWSER_LANGUAGE',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
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
        key: 'phone_number',
        name: 'Phone Number',
        attributeI18nKey: 'PHONE_NUMBER',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_6,
      },
      {
        key: 'assignee_id',
        name: 'Assignee',
        attributeI18nKey: 'ASSIGNEE_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'team_id',
        name: 'Team',
        attributeI18nKey: 'TEAM_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'email',
        name: 'Email',
        attributeI18nKey: 'EMAIL',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
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
      {
        key: 'contact_label',
        name: 'Contact Label',
        attributeI18nKey: 'CONTACT_LABEL',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'conversation_label',
        name: 'Conversation Label',
        attributeI18nKey: 'PRIORITY',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
    ],
    actions: [
      {
        key: 'assign_agent',
        label: 'Assign to agent',
        inputType: 'search_select',
      },
      {
        key: 'assign_team',
        label: 'Assign a team',
        inputType: 'search_select',
      },
      {
        key: 'add_label',
        label: 'Add conversation label',
        inputType: 'multi_select',
      },
      {
        key: 'remove_label',
        label: 'Remove conversation label',
        inputType: 'multi_select',
      },
      {
        key: 'add_contact_label',
        label: 'Add contact label',
        inputType: 'multi_select',
      },
      {
        key: 'remove_contact_label',
        label: 'Remove contact label',
        inputType: 'multi_select',
      },
      {
        key: 'send_email_to_team',
        label: 'Send an email to team',
        inputType: 'team_message',
      },
      {
        key: 'send_email_transcript',
        label: 'Send an email transcript',
        inputType: 'email',
      },
      {
        key: 'mute_conversation',
        label: 'Mute conversation',
        inputType: null,
      },
      {
        key: 'snooze_conversation',
        label: 'Snooze conversation',
        inputType: null,
      },
      {
        key: 'resolve_conversation',
        label: 'Resolve conversation',
        inputType: null,
      },
      {
        key: 'send_webhook_event',
        label: 'Send Webhook Event',
        inputType: 'url',
      },
      {
        key: 'send_attachment',
        label: 'Send Attachment',
        inputType: 'attachment',
      },
      {
        key: 'send_message',
        label: 'Send a message',
        inputType: 'textarea',
      },
      {
        key: 'send_template',
        label: 'Send a template',
        inputType: 'template',
      },
      {
        key: 'change_priority',
        label: 'Change Priority',
        inputType: 'search_select',
      },
      {
        key: 'add_sla',
        label: 'Add SLA',
        inputType: 'search_select',
      },
    ],
  },
  conversation_opened: {
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
      {
        key: 'contact_label',
        name: 'Contact Label',
        attributeI18nKey: 'CONTACT_LABEL',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'conversation_label',
        name: 'Conversation Label',
        attributeI18nKey: 'PRIORITY',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
    ],
    actions: [
      {
        key: 'assign_agent',
        label: 'Assign to agent',
        inputType: 'search_select',
      },
      {
        key: 'assign_team',
        label: 'Assign a team',
        inputType: 'search_select',
      },
      {
        key: 'add_label',
        label: 'Add conversation label',
        inputType: 'multi_select',
      },
      {
        key: 'remove_label',
        label: 'Remove conversation label',
        inputType: 'multi_select',
      },
      {
        key: 'add_contact_label',
        label: 'Add contact label',
        inputType: 'multi_select',
      },
      {
        key: 'remove_contact_label',
        label: 'Remove contact label',
        inputType: 'multi_select',
      },
      {
        key: 'send_email_to_team',
        label: 'Send an email to team',
        inputType: 'team_message',
      },
      {
        key: 'send_email_transcript',
        label: 'Send an email transcript',
        inputType: 'email',
      },
      {
        key: 'mute_conversation',
        label: 'Mute conversation',
        inputType: null,
      },
      {
        key: 'snooze_conversation',
        label: 'Snooze conversation',
        inputType: null,
      },
      {
        key: 'resolve_conversation',
        label: 'Resolve conversation',
        inputType: null,
      },
      {
        key: 'send_webhook_event',
        label: 'Send Webhook Event',
        inputType: 'url',
      },
      {
        key: 'send_attachment',
        label: 'Send Attachment',
        inputType: 'attachment',
      },
      {
        key: 'send_message',
        label: 'Send a message',
        inputType: 'textarea',
      },
      {
        key: 'send_template',
        label: 'Send a template',
        inputType: 'template',
      },
      {
        key: 'change_priority',
        label: 'Change Priority',
        inputType: 'search_select',
      },
      {
        key: 'add_sla',
        label: 'Add SLA',
        inputType: 'search_select',
      },
    ],
  },

  order_created: {
    conditions: [
      {
        key: 'order_number',
        name: 'Order Number',
        attributeI18nKey: 'ORDER_NUMBER',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'custom_status',
        name: 'Status',
        attributeI18nKey: 'STATUS',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'platform',
        name: 'Platform',
        attributeI18nKey: 'PLATFORM',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'payment_status',
        name: 'Payment Status',
        attributeI18nKey: 'PAYMENT_STATUS',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'contact_label',
        name: 'Contact Label',
        attributeI18nKey: 'CONTACT_LABEL',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
    ],
    actions: [
      {
        key: 'add_contact_label',
        label: 'Add contact label',
        inputType: 'multi_select',
      },
      {
        key: 'remove_contact_label',
        label: 'Remove contact label',
        inputType: 'multi_select',
      },
      {
        key: 'send_template',
        label: 'Send a template',
        inputType: 'template',
      },
      {
        key: 'add_sla',
        label: 'Add SLA',
        inputType: 'search_select',
      },
    ],
  },
  order_status_updated: {
    conditions: [
      {
        key: 'order_number',
        name: 'Order Number',
        attributeI18nKey: 'ORDER_NUMBER',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'custom_status',
        name: 'Status',
        attributeI18nKey: 'STATUS',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'platform',
        name: 'Platform',
        attributeI18nKey: 'PLATFORM',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
      {
        key: 'payment_status',
        name: 'Payment Status',
        attributeI18nKey: 'PAYMENT_STATUS',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
      {
        key: 'contact_label',
        name: 'Contact Label',
        attributeI18nKey: 'CONTACT_LABEL',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
    ],
    actions: [
      {
        key: 'add_contact_label',
        label: 'Add contact label',
        inputType: 'multi_select',
      },
      {
        key: 'remove_contact_label',
        label: 'Remove contact label',
        inputType: 'multi_select',
      },
      {
        key: 'send_template',
        label: 'Send a template',
        inputType: 'template',
      },
      {
        key: 'add_sla',
        label: 'Add SLA',
        inputType: 'search_select',
      },
    ],
  },
  cart_recovery: {
    conditions: [
      {
        key: 'none',
        name: 'None',
        attributeI18nKey: 'NONE',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'contact_label',
        name: 'Contact Label',
        attributeI18nKey: 'CONTACT_LABEL',
        inputType: 'multi_select',
        filterOperators: OPERATOR_TYPES_3,
      },
    ],
    actions: [
      {
        key: 'add_contact_label',
        label: 'Add contact label',
        inputType: 'multi_select',
      },
      {
        key: 'remove_contact_label',
        label: 'Remove contact label',
        inputType: 'multi_select',
      },
      {
        key: 'send_template',
        label: 'Send a template',
        inputType: 'template',
      },
      {
        key: 'add_sla',
        label: 'Add SLA',
        inputType: 'search_select',
      },
    ],
  },
};

export const AUTOMATION_RULE_EVENTS = [
  {
    key: 'conversation_created',
    value: 'Conversation Created',
  },
  {
    key: 'conversation_updated',
    value: 'Conversation Updated',
  },
  {
    key: 'message_created',
    value: 'Message Created',
  },
  {
    key: 'conversation_opened',
    value: 'Conversation Opened',
  },
];

export const AUTOMATION_RULE_INTEGRATION_EVENTS = [
  {
    key: 'order_created',
    value: 'Order Created',
  },
  {
    key: 'order_status_updated',
    value: 'Order Status Updated',
  },
  {
    key: 'cart_recovery',
    value: 'Cart Recovery',
  },
];

export const AUTOMATION_ACTION_TYPES = [
  {
    key: 'assign_agent',
    label: 'Assign to agent',
    inputType: 'search_select',
  },
  {
    key: 'assign_team',
    label: 'Assign a team',
    inputType: 'search_select',
  },
  {
    key: 'add_label',
    label: 'Add conversation label',
    inputType: 'multi_select',
  },
  {
    key: 'remove_label',
    label: 'Remove conversation label',
    inputType: 'multi_select',
  },
  {
    key: 'add_contact_label',
    label: 'Add contact label',
    inputType: 'multi_select',
  },
  {
    key: 'remove_contact_label',
    label: 'Remove contact label',
    inputType: 'multi_select',
  },
  {
    key: 'send_email_to_team',
    label: 'Send an email to team',
    inputType: 'team_message',
  },
  {
    key: 'send_email_transcript',
    label: 'Send an email transcript',
    inputType: 'email',
  },
  {
    key: 'mute_conversation',
    label: 'Mute conversation',
    inputType: null,
  },
  {
    key: 'snooze_conversation',
    label: 'Snooze conversation',
    inputType: null,
  },
  {
    key: 'resolve_conversation',
    label: 'Resolve conversation',
    inputType: null,
  },
  {
    key: 'send_webhook_event',
    label: 'Send Webhook Event',
    inputType: 'url',
  },
  {
    key: 'send_attachment',
    label: 'Send Attachment',
    inputType: 'attachment',
  },
  {
    key: 'send_message',
    label: 'Send a message',
    inputType: 'textarea',
  },
  {
    key: 'send_template',
    label: 'Send a template',
    inputType: 'template',
  },
  {
    key: 'change_priority',
    label: 'Change Priority',
    inputType: 'search_select',
  },
  {
    key: 'add_sla',
    label: 'Add SLA',
    inputType: 'search_select',
  },
];

export const INTERVAL_TYPES = [
  { value: 'minutes', label: 'minutes' },
  { value: 'hours', label: 'hours' },
  { value: 'days', label: 'days' },
];
