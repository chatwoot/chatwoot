export const templates = [
  {
    id: 1,
    name: 'Welcome Message',
    category: 'marketing',
    language: 'en',
    status: 'approved',
    inbox_id: 1,
    channel_type: 'Channel::Whatsapp',
    parameter_format: 'named',
    content: {
      components: [
        {
          type: 'BODY',
          text: 'Welcome {{customer_name}} to our service!',
          example: {
            body_text_named_params: [
              { param_name: 'customer_name', example: 'John' },
            ],
          },
        },
      ],
    },
    created_at: '2023-01-01T00:00:00Z',
    updated_at: '2023-01-01T00:00:00Z',
  },
  {
    id: 2,
    name: 'Order Confirmation',
    category: 'utility',
    language: 'en',
    status: 'pending',
    inbox_id: 1,
    channel_type: 'Channel::Whatsapp',
    parameter_format: 'positional',
    content: {
      components: [
        {
          type: 'HEADER',
          format: 'TEXT',
          text: 'Order Confirmation',
        },
        {
          type: 'BODY',
          text: 'Your order {{1}} has been confirmed.',
          example: {
            body_text: ['ORD-123'],
          },
        },
      ],
    },
    created_at: '2023-01-02T00:00:00Z',
    updated_at: '2023-01-02T00:00:00Z',
  },
  {
    id: 3,
    name: 'Support Template',
    category: 'utility',
    language: 'es',
    status: 'rejected',
    inbox_id: 2,
    channel_type: 'Channel::Whatsapp',
    parameter_format: 'positional',
    content: {
      components: [
        {
          type: 'BODY',
          text: 'Thank you for contacting support.',
        },
      ],
    },
    created_at: '2023-01-03T00:00:00Z',
    updated_at: '2023-01-03T00:00:00Z',
  },
];

export const builderConfig = {
  name: 'Test Template',
  language: 'en',
  channelType: 'Channel::Whatsapp',
  inboxId: 1,
  category: 'utility',
  templateId: null,
};

export const templateResponse = {
  data: templates[0],
};

export const templatesResponse = {
  data: templates,
};

export const createTemplatePayload = {
  name: 'New Template',
  category: 'marketing',
  language: 'en',
  parameter_format: 'named',
  content: {
    components: [
      {
        type: 'BODY',
        text: 'Hello {{name}}!',
      },
    ],
  },
};

export const createTemplateResponse = {
  data: {
    id: 4,
    ...createTemplatePayload,
    status: 'pending',
    inbox_id: 1,
    channel_type: 'Channel::Whatsapp',
    created_at: '2023-01-04T00:00:00Z',
    updated_at: '2023-01-04T00:00:00Z',
  },
};

export const uiFlags = {
  isFetching: false,
  isCreating: false,
  isUpdating: false,
  isDeleting: false,
};
