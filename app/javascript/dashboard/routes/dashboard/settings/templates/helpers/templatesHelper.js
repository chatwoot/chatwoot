// Demo function to return template data
// This will be replaced with actual API calls when backend support is added

export const getTemplatesDemo = () => {
  return Promise.resolve([
    {
      id: 1,
      name: 'Welcome Message',
      category: 'marketing',
      channel_type: 'whatsapp',
      status: 'approved',
      language: 'en',
      content: 'Welcome to our service! How can we help you today?',
      created_at: '2024-01-15T10:30:00Z',
      updated_at: '2024-01-15T10:30:00Z',
      components: [
        {
          type: 'HEADER',
          format: 'TEXT',
          text: 'Welcome!',
        },
        {
          type: 'BODY',
          text: 'Welcome to our service! How can we help you today?',
        },
      ],
    },
    {
      id: 2,
      name: 'Order Confirmation',
      category: 'utility',
      channel_type: 'whatsapp',
      status: 'approved',
      language: 'en',
      content: 'Your order {{1}} has been confirmed. Expected delivery: {{2}}',
      created_at: '2024-01-16T14:20:00Z',
      updated_at: '2024-01-16T14:20:00Z',
      components: [
        {
          type: 'HEADER',
          format: 'TEXT',
          text: 'Order Update',
        },
        {
          type: 'BODY',
          text: 'Your order {{1}} has been confirmed. Expected delivery: {{2}}',
          example: {
            body_text: [['#12345', 'January 25, 2024']],
          },
        },
      ],
    },
    {
      id: 3,
      name: 'Support Hours',
      category: 'utility',
      channel_type: 'whatsapp',
      status: 'approved',
      language: 'en',
      content: 'Our support team is available Monday to Friday, 9 AM to 6 PM.',
      created_at: '2024-01-17T09:15:00Z',
      updated_at: '2024-01-17T09:15:00Z',
      components: [
        {
          type: 'BODY',
          text: 'Our support team is available Monday to Friday, 9 AM to 6 PM.',
        },
      ],
    },
    {
      id: 4,
      name: 'Account Verification',
      category: 'authentication',
      channel_type: 'whatsapp',
      status: 'approved',
      language: 'en',
      content:
        'Your verification code is {{1}}. Do not share this code with anyone.',
      created_at: '2024-01-18T16:45:00Z',
      updated_at: '2024-01-18T16:45:00Z',
      components: [
        {
          type: 'HEADER',
          format: 'TEXT',
          text: 'Security Code',
        },
        {
          type: 'BODY',
          text: 'Your verification code is {{1}}. Do not share this code with anyone.',
          example: {
            body_text: [['123456']],
          },
        },
      ],
    },
    {
      id: 5,
      name: 'Special Offer',
      category: 'marketing',
      channel_type: 'whatsapp',
      status: 'pending',
      language: 'en',
      content:
        'Limited time offer! Get 20% off your next purchase. Use code: {{1}}',
      created_at: '2024-01-19T11:30:00Z',
      updated_at: '2024-01-19T11:30:00Z',
      components: [
        {
          type: 'HEADER',
          format: 'TEXT',
          text: 'Special Offer',
        },
        {
          type: 'BODY',
          text: 'Limited time offer! Get 20% off your next purchase. Use code: {{1}}',
          example: {
            body_text: [['SAVE20']],
          },
        },
        {
          type: 'FOOTER',
          text: 'Offer valid until end of month',
        },
      ],
    },
  ]);
};

export const createTemplate = templateData => {
  // Demo function - will be replaced with actual API call
  const template = {
    id: Date.now(),
    ...templateData,
    status: 'pending',
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
  };

  // If components are provided, use them; otherwise generate from content
  if (!template.components && template.content) {
    template.components = [
      {
        type: 'BODY',
        text: template.content,
      },
    ];
  }

  return Promise.resolve(template);
};

export const updateTemplate = (id, templateData) => {
  // Demo function - will be replaced with actual API call
  return Promise.resolve({
    id,
    ...templateData,
    updated_at: new Date().toISOString(),
  });
};

export const deleteTemplate = id => {
  // Demo function - will be replaced with actual API call
  return Promise.resolve({ success: true, id });
};
