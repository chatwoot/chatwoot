export default {
  customFields: {
    pre_chat_message: 'Share your queries or comments here.',
    pre_chat_fields: [
      {
        label: 'Email Id',
        name: 'emailAddress',
        type: 'email',
        field_type: 'standard',
        required: false,
        enabled: false,
      },
      {
        label: 'Full name',
        name: 'fullName',
        type: 'text',
        field_type: 'standard',
        required: false,
        enabled: false,
      },
      {
        label: 'Phone number',
        name: 'phoneNumber',
        type: 'text',
        field_type: 'standard',
        required: false,
        enabled: false,
      },
    ],
  },
  customAttributes: [
    {
      id: 101,
      attribute_description: 'Order Identifier',
      attribute_display_name: 'Order Id',
      attribute_display_type: 'number',
      attribute_key: 'order_id',
      attribute_model: 'conversation_attribute',
      attribute_values: Array(0),
      created_at: '2021-11-29T10:20:04.563Z',
    },
  ],
};
