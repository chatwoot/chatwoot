export const action = {
  action_name: 'send_attachment',
  action_params: [59],
};

export const files = [
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
];

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
];

export const automation = {
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
