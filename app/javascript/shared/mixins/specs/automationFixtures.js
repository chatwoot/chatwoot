export const action = {
  action_name: 'assign_team',
  action_params: [
    {
      id: 1,
      name: 'sales team',
      description: 'This is our internal sales team',
      allow_auto_assign: true,
      account_id: 1,
      is_member: true,
    },
  ],
};

export const files = [
  {
    id: 49,
    automation_rule_id: 158,
    file_type: 'image/jpeg',
    account_id: 1,
    file_url:
      'http://localhost:3000/rails/active_storage/blobs/redirect/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBQdz09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--6325fd90e5d921bc441f4682d0262bda1c3ac848/IMG_2460.JPG',
    blob_id: 58,
    filename: 'IMG_2460.JPG',
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
