import allLanguages from '../../../dashboard/components/widgets/conversation/advancedFilterItems/languages.js';

import allCountries from '../../../shared/constants/countries.js';

export const customAttributes = [
  {
    id: 1,
    attribute_display_name: 'Signed Up At',
    attribute_display_type: 'date',
    attribute_description: 'This is a test',
    attribute_key: 'signed_up_at',
    attribute_values: [],
    attribute_model: 'conversation_attribute',
    default_value: null,
    created_at: '2022-01-26T08:06:39.470Z',
    updated_at: '2022-01-26T08:06:39.470Z',
  },
  {
    id: 2,
    attribute_display_name: 'Prime User',
    attribute_display_type: 'checkbox',
    attribute_description: 'Test',
    attribute_key: 'prime_user',
    attribute_values: [],
    attribute_model: 'contact_attribute',
    default_value: null,
    created_at: '2022-01-26T08:07:29.664Z',
    updated_at: '2022-01-26T08:07:29.664Z',
  },
  {
    id: 3,
    attribute_display_name: 'Test',
    attribute_display_type: 'text',
    attribute_description: 'Test',
    attribute_key: 'test',
    attribute_values: [],
    attribute_model: 'conversation_attribute',
    default_value: null,
    created_at: '2022-01-26T08:07:58.325Z',
    updated_at: '2022-01-26T08:07:58.325Z',
  },
  {
    id: 4,
    attribute_display_name: 'Link',
    attribute_display_type: 'link',
    attribute_description: 'Test',
    attribute_key: 'link',
    attribute_values: [],
    attribute_model: 'conversation_attribute',
    default_value: null,
    created_at: '2022-02-07T07:31:51.562Z',
    updated_at: '2022-02-07T07:31:51.562Z',
  },
  {
    id: 5,
    attribute_display_name: 'My List',
    attribute_display_type: 'list',
    attribute_description: 'This is a sample list',
    attribute_key: 'my_list',
    attribute_values: ['item1', 'item2', 'item3'],
    attribute_model: 'conversation_attribute',
    default_value: null,
    created_at: '2022-02-21T20:31:34.175Z',
    updated_at: '2022-02-21T20:31:34.175Z',
  },
  {
    id: 6,
    attribute_display_name: 'My Check',
    attribute_display_type: 'checkbox',
    attribute_description: 'Test Checkbox',
    attribute_key: 'my_check',
    attribute_values: [],
    attribute_model: 'conversation_attribute',
    default_value: null,
    created_at: '2022-02-21T20:31:53.385Z',
    updated_at: '2022-02-21T20:31:53.385Z',
  },
  {
    id: 7,
    attribute_display_name: 'ConList',
    attribute_display_type: 'list',
    attribute_description: 'This is a test list\n',
    attribute_key: 'conlist',
    attribute_values: ['Hello', 'Test', 'Test2'],
    attribute_model: 'contact_attribute',
    default_value: null,
    created_at: '2022-02-28T12:58:05.005Z',
    updated_at: '2022-02-28T12:58:05.005Z',
  },
  {
    id: 8,
    attribute_display_name: 'asdf',
    attribute_display_type: 'link',
    attribute_description: 'This is a some text',
    attribute_key: 'asdf',
    attribute_values: [],
    attribute_model: 'contact_attribute',
    default_value: null,
    created_at: '2022-04-21T05:48:16.168Z',
    updated_at: '2022-04-21T05:48:16.168Z',
  },
];
export const emptyAutomation = {
  name: null,
  description: null,
  event_name: 'conversation_created',
  conditions: [
    {
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: '',
      query_operator: 'and',
    },
  ],
  actions: [
    {
      action_name: 'assign_team',
      action_params: [],
    },
  ],
};
export const filterAttributes = [
  {
    key: 'status',
    name: 'Status',
    attributeI18nKey: 'STATUS',
    inputType: 'multi_select',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
    ],
  },
  {
    key: 'browser_language',
    name: 'Browser Language',
    attributeI18nKey: 'BROWSER_LANGUAGE',
    inputType: 'search_select',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
    ],
  },
  {
    key: 'country_code',
    name: 'Country',
    attributeI18nKey: 'COUNTRY_NAME',
    inputType: 'search_select',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
    ],
  },
  {
    key: 'referer',
    name: 'Referrer Link',
    attributeI18nKey: 'REFERER_LINK',
    inputType: 'plain_text',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
      { value: 'contains', label: 'Contains' },
      { value: 'does_not_contain', label: 'Does not contain' },
    ],
  },
  {
    key: 'inbox_id',
    name: 'Inbox',
    attributeI18nKey: 'INBOX',
    inputType: 'multi_select',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
    ],
  },
  {
    key: 'conversation_custom_attribute',
    name: 'Conversation Custom Attributes',
    disabled: true,
  },
  {
    key: 'signed_up_at',
    name: 'Signed Up At',
    inputType: 'date',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
      { value: 'is_present', label: 'Is present' },
      { value: 'is_not_present', label: 'Is not present' },
      { value: 'is_greater_than', label: 'Is greater than' },
      { value: 'is_less_than', label: 'Is less than' },
    ],
  },
  {
    key: 'test',
    name: 'Test',
    inputType: 'plain_text',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
      { value: 'is_present', label: 'Is present' },
      { value: 'is_not_present', label: 'Is not present' },
    ],
  },
  {
    key: 'link',
    name: 'Link',
    inputType: 'plain_text',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
    ],
  },
  {
    key: 'my_list',
    name: 'My List',
    inputType: 'search_select',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
    ],
  },
  {
    key: 'my_check',
    name: 'My Check',
    inputType: 'search_select',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
    ],
  },
  {
    key: 'contact_custom_attribute',
    name: 'Contact Custom Attributes',
    disabled: true,
  },
  {
    key: 'prime_user',
    name: 'Prime User',
    inputType: 'search_select',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
    ],
  },
  {
    key: 'conlist',
    name: 'ConList',
    inputType: 'search_select',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
    ],
  },
  {
    key: 'asdf',
    name: 'asdf',
    inputType: 'plain_text',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
    ],
  },
];
export const automation = {
  id: 164,
  account_id: 1,
  name: 'Attachment',
  description: 'Yo',
  event_name: 'conversation_created',
  conditions: [
    {
      values: [{ id: 'open', name: 'Open' }],
      attribute_key: 'status',
      filter_operator: 'equal_to',
      query_operator: 'and',
    },
  ],
  actions: [{ action_name: 'send_attachment', action_params: [59] }],
  created_on: 1652717181,
  active: true,
  files: [
    {
      id: 50,
      automation_rule_id: 164,
      file_type: 'image/jpeg',
      account_id: 1,
      file_url:
        'http://localhost:3000/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBRQT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--965b4c27f4c5e47c526f0f38266b25417b72e5dd/pfp.jpeg',
      blob_id: 59,
      filename: 'pfp.jpeg',
    },
  ],
};
export const agents = [
  {
    id: 1,
    account_id: 1,
    availability_status: 'online',
    auto_offline: true,
    confirmed: true,
    email: 'john@acme.inc',
    available_name: 'Fayaz',
    name: 'Fayaz',
    role: 'administrator',
    thumbnail:
      'https://www.gravatar.com/avatar/0d722ac7bc3b3c92c030d0da9690d981?d=404',
  },
  {
    id: 5,
    account_id: 1,
    availability_status: 'offline',
    auto_offline: true,
    confirmed: true,
    email: 'john@doe.com',
    available_name: 'John',
    name: 'John',
    role: 'agent',
    thumbnail:
      'https://www.gravatar.com/avatar/6a6c19fea4a3676970167ce51f39e6ee?d=404',
  },
];
export const booleanFilterOptions = [
  {
    id: true,
    name: 'True',
  },
  {
    id: false,
    name: 'False',
  },
];
export const teams = [
  {
    id: 1,
    name: 'sales team',
    description: 'This is our internal sales team',
    allow_auto_assign: true,
    account_id: 1,
    is_member: true,
  },
  {
    id: 2,
    name: 'fayaz',
    description: 'Test',
    allow_auto_assign: true,
    account_id: 1,
    is_member: false,
  },
];
export const campaigns = [];
export const contacts = [
  {
    additional_attributes: {},
    availability_status: 'offline',
    email: 'asd123123@asd.com',
    id: 32,
    name: 'asd123123',
    phone_number: null,
    identifier: null,
    thumbnail:
      'https://www.gravatar.com/avatar/46000d9a1eef3e24a02ca9d6c2a8f494?d=404',
    custom_attributes: {},
    conversations_count: 5,
    last_activity_at: 1650519706,
  },
  {
    additional_attributes: {},
    availability_status: 'offline',
    email: 'barry_allen@a.com',
    id: 29,
    name: 'barry_allen',
    phone_number: null,
    identifier: null,
    thumbnail:
      'https://www.gravatar.com/avatar/ab5ff99efa3bc1f74db1dc2885f9e2ce?d=404',
    custom_attributes: {},
    conversations_count: 1,
    last_activity_at: 1643728899,
  },
];
export const inboxes = [
  {
    id: 1,
    avatar_url: '',
    channel_id: 1,
    name: 'Acme Support',
    channel_type: 'Channel::WebWidget',
    greeting_enabled: false,
    greeting_message: '',
    working_hours_enabled: false,
    enable_email_collect: true,
    csat_survey_enabled: true,
    enable_auto_assignment: true,
    out_of_office_message:
      'We are unavailable at the moment. Leave a message we will respond once we are back.',
    working_hours: [
      {
        day_of_week: 0,
        closed_all_day: true,
        open_hour: null,
        open_minutes: null,
        close_hour: null,
        close_minutes: null,
        open_all_day: false,
      },
      {
        day_of_week: 1,
        closed_all_day: false,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
        open_all_day: false,
      },
      {
        day_of_week: 2,
        closed_all_day: false,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
        open_all_day: false,
      },
      {
        day_of_week: 3,
        closed_all_day: false,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
        open_all_day: false,
      },
      {
        day_of_week: 4,
        closed_all_day: false,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
        open_all_day: false,
      },
      {
        day_of_week: 5,
        closed_all_day: false,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
        open_all_day: false,
      },
      {
        day_of_week: 6,
        closed_all_day: true,
        open_hour: null,
        open_minutes: null,
        close_hour: null,
        close_minutes: null,
        open_all_day: false,
      },
    ],
    timezone: 'America/Los_Angeles',
    callback_webhook_url: null,
    allow_messages_after_resolved: true,
    widget_color: '#1f93ff',
    website_url: 'https://acme.inc',
    hmac_mandatory: false,
    welcome_title: '',
    welcome_tagline: '',
    web_widget_script:
      '\n    <script>\n      (function(d,t) {\n        var BASE_URL="http://localhost:3000";\n        var g=d.createElement(t),s=d.getElementsByTagName(t)[0];\n        g.src=BASE_URL+"/packs/js/sdk.js";\n        g.defer = true;\n        g.async = true;\n        s.parentNode.insertBefore(g,s);\n        g.onload=function(){\n          window.chatwootSDK.run({\n            websiteToken: \'yZ7USzaEs7hrwUAHLGwjbxJ1\',\n            baseUrl: BASE_URL\n          })\n        }\n      })(document,"script");\n    </script>\n    ',
    website_token: 'yZ7USzaEs7hrwUAHLGwjbxJ1',
    selected_feature_flags: ['attachments', 'emoji_picker', 'end_conversation'],
    reply_time: 'in_a_few_minutes',
    hmac_token: 'rRJW1BHu4aFMMey4SE7tWr8A',
    pre_chat_form_enabled: false,
    pre_chat_form_options: {
      pre_chat_fields: [
        {
          name: 'emailAddress',
          type: 'email',
          label: 'Email Id',
          enabled: false,
          required: true,
          field_type: 'standard',
        },
        {
          name: 'fullName',
          type: 'text',
          label: 'Full name',
          enabled: false,
          required: false,
          field_type: 'standard',
        },
        {
          name: 'phoneNumber',
          type: 'text',
          label: 'Phone number',
          enabled: false,
          required: false,
          field_type: 'standard',
        },
      ],
      pre_chat_message: 'Share your queries or comments here.',
    },
    continuity_via_email: true,
    phone_number: null,
  },
  {
    id: 2,
    avatar_url: '',
    channel_id: 1,
    name: 'Email',
    channel_type: 'Channel::Email',
    greeting_enabled: false,
    greeting_message: null,
    working_hours_enabled: false,
    enable_email_collect: true,
    csat_survey_enabled: false,
    enable_auto_assignment: true,
    out_of_office_message: null,
    working_hours: [
      {
        day_of_week: 0,
        closed_all_day: true,
        open_hour: null,
        open_minutes: null,
        close_hour: null,
        close_minutes: null,
        open_all_day: false,
      },
      {
        day_of_week: 1,
        closed_all_day: false,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
        open_all_day: false,
      },
      {
        day_of_week: 2,
        closed_all_day: false,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
        open_all_day: false,
      },
      {
        day_of_week: 3,
        closed_all_day: false,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
        open_all_day: false,
      },
      {
        day_of_week: 4,
        closed_all_day: false,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
        open_all_day: false,
      },
      {
        day_of_week: 5,
        closed_all_day: false,
        open_hour: 9,
        open_minutes: 0,
        close_hour: 17,
        close_minutes: 0,
        open_all_day: false,
      },
      {
        day_of_week: 6,
        closed_all_day: true,
        open_hour: null,
        open_minutes: null,
        close_hour: null,
        close_minutes: null,
        open_all_day: false,
      },
    ],
    timezone: 'UTC',
    callback_webhook_url: null,
    allow_messages_after_resolved: true,
    widget_color: null,
    website_url: null,
    hmac_mandatory: null,
    welcome_title: null,
    welcome_tagline: null,
    web_widget_script: null,
    website_token: null,
    selected_feature_flags: null,
    reply_time: null,
    phone_number: null,
    forward_to_email: '9ae8ebb96c7f2d6705009f5add6d1a2d@false',
    email: 'fayaz@chatwoot.com',
    imap_login: '',
    imap_password: '',
    imap_address: '',
    imap_port: 0,
    imap_enabled: false,
    imap_enable_ssl: true,
    smtp_login: '',
    smtp_password: '',
    smtp_address: '',
    smtp_port: 0,
    smtp_enabled: false,
    smtp_domain: '',
    smtp_enable_ssl_tls: false,
    smtp_enable_starttls_auto: true,
    smtp_openssl_verify_mode: 'none',
    smtp_authentication: 'login',
  },
];
export const labels = [
  {
    id: 2,
    title: 'testlabel',
  },
  {
    id: 1,
    title: 'snoozes',
  },
];
export const statusFilterOptions = [
  { id: 'open', name: 'Open' },
  { id: 'resolved', name: 'Resolved' },
  { id: 'pending', name: 'Pending' },
  { id: 'snoozed', name: 'Snoozed' },
  { id: 'all', name: 'All' },
];
export const languages = allLanguages;
export const countries = allCountries;
export const MESSAGE_CONDITION_VALUES = [
  {
    id: 'incoming',
    name: 'Incoming Message',
  },
  {
    id: 'outgoing',
    name: 'Outgoing Message',
  },
];

export const automationToSubmit = {
  name: 'Fayaz',
  description: 'Hello',
  event_name: 'conversation_created',
  conditions: [
    {
      attribute_key: 'status',
      filter_operator: 'equal_to',
      values: [{ id: 'open', name: 'Open' }],
      query_operator: 'and',
      custom_attribute_type: '',
    },
  ],
  actions: [
    { action_name: 'add_label', action_params: [{ id: 2, name: 'testlabel' }] },
  ],
};

export const savedAutomation = {
  id: 165,
  account_id: 1,
  name: 'Fayaz',
  description: 'Hello',
  event_name: 'conversation_created',
  conditions: [
    {
      values: ['open'],
      attribute_key: 'status',
      filter_operator: 'equal_to',
    },
  ],
  actions: [
    {
      action_name: 'add_label',
      action_params: [2],
    },
  ],
  created_on: 1652776043,
  active: true,
};

export const contactAttrs = [
  {
    key: 'contact_list',
    name: 'Contact List',
    inputType: 'search_select',
    filterOperators: [
      {
        value: 'equal_to',
        label: 'Equal to',
      },
      {
        value: 'not_equal_to',
        label: 'Not equal to',
      },
    ],
  },
];
export const conversationAttrs = [
  {
    key: 'text_attr',
    name: 'Text Attr',
    inputType: 'plain_text',
    filterOperators: [
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
    ],
  },
];
export const expectedOutputForCustomAttributeGenerator = [
  {
    key: 'conversation_custom_attribute',
    name: 'Conversation Custom Attributes',
    disabled: true,
  },
  {
    key: 'text_attr',
    name: 'Text Attr',
    inputType: 'plain_text',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
      { value: 'is_present', label: 'Is present' },
      { value: 'is_not_present', label: 'Is not present' },
    ],
  },
  {
    key: 'contact_custom_attribute',
    name: 'Contact Custom Attributes',
    disabled: true,
  },
  {
    key: 'contact_list',
    name: 'Contact List',
    inputType: 'search_select',
    filterOperators: [
      { value: 'equal_to', label: 'Equal to' },
      { value: 'not_equal_to', label: 'Not equal to' },
    ],
  },
];
