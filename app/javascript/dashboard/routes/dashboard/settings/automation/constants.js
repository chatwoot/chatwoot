const OPERATOR_TYPES_1 = [
  {
    value: 'equal_to',
    label: 'Equal to',
  },
  {
    value: 'not_equal_to',
    label: 'Not equal to',
  },
];

const OPERATOR_TYPES_2 = [
  {
    value: 'equal_to',
    label: 'Equal to',
  },
  {
    value: 'not_equal_to',
    label: 'Not equal to',
  },
  {
    value: 'contains',
    label: 'Contains',
  },
  {
    value: 'does_not_contain',
    label: 'Does not contain',
  },
];

const OPERATOR_TYPES_3 = [
  {
    value: 'equal_to',
    label: 'Equal to',
  },
  {
    value: 'not_equal_to',
    label: 'Not equal to',
  },
  {
    value: 'is_present',
    label: 'Is present',
  },
  {
    value: 'is_not_present',
    label: 'Is not present',
  },
];

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
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
    ],
    actions: [
      {
        key: 'assign_team',
        name: 'Assign a team',
        attributeI18nKey: 'ASSIGN_TEAM',
      },
      {
        key: 'add_label',
        name: 'Add a label',
        attributeI18nKey: 'ADD_LABEL',
      },
      // {
      //   key: 'send_email_to_team',
      //   name: 'Send an email to team',
      //   attributeI18nKey: 'SEND_MESSAGE',
      // },
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
        key: 'country_code',
        name: 'Country',
        attributeI18nKey: 'COUNTRY_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_1,
      },
      {
        key: 'referrer',
        name: 'Referrer Link',
        attributeI18nKey: 'REFERER_LINK',
        inputType: 'plain_text',
        filterOperators: OPERATOR_TYPES_2,
      },
    ],
    actions: [
      {
        key: 'assign_team',
        name: 'Assign a team',
        attributeI18nKey: 'ASSIGN_TEAM',
      },
      // {
      //   key: 'send_email_to_team',
      //   name: 'Send an email to team',
      //   attributeI18nKey: 'SEND_MESSAGE',
      // },
      {
        key: 'assign_agent',
        name: 'Assign an agent',
        attributeI18nKey: 'ASSIGN_AGENT',
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
        key: 'team_id',
        name: 'Team',
        attributeI18nKey: 'TEAM_NAME',
        inputType: 'search_select',
        filterOperators: OPERATOR_TYPES_3,
      },
    ],
    actions: [
      {
        key: 'assign_team',
        name: 'Assign a team',
        attributeI18nKey: 'ASSIGN_TEAM',
      },
      // {
      //   key: 'send_email_to_team',
      //   name: 'Send an email to team',
      //   attributeI18nKey: 'SEND_MESSAGE',
      // },
      {
        key: 'assign_agent',
        name: 'Assign an agent',
        attributeI18nKey: 'ASSIGN_AGENT',
        attributeKey: 'assignee_id',
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
];

export const AUTOMATION_ACTION_TYPES = [
  {
    key: 'assign_team',
    label: 'Assign a team',
  },
  {
    key: 'add_label',
    label: 'Add a label',
  },
  // {
  //   key: 'send_email_to_team',
  //   label: 'Send an email to team',
  // },
];
