export const whatsAppTemplates = [
  {
    id: '1381151706284063',
    name: 'event_invitation_static',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        text: "You're invited to {{event_name}} at {{location}}, Join us for an amazing experience!",
        type: 'BODY',
        example: {
          body_text_named_params: [
            {
              example: 'F1',
              param_name: 'event_name',
            },
            {
              example: 'Dubai',
              param_name: 'location',
            },
          ],
        },
      },
      {
        type: 'BUTTONS',
        buttons: [
          {
            url: 'https://events.example.com/register',
            text: 'Visit website',
            type: 'URL',
          },
          {
            url: 'https://maps.app.goo.gl/YoWAzRj1GDuxs6qz8',
            text: 'Get Directions',
            type: 'URL',
          },
        ],
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'NAMED',
  },
  {
    id: '767076159336759',
    name: 'purchase_receipt',
    status: 'APPROVED',
    category: 'UTILITY',
    language: 'en_US',
    components: [
      {
        type: 'HEADER',
        format: 'DOCUMENT',
        example: {
          header_handle: [
            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
          ],
        },
      },
      {
        text: 'Thank you for using your {{1}} card at {{2}}. Your {{3}} is attached as a PDF.',
        type: 'BODY',
        example: {
          body_text: [['credit', 'CS Mutual', 'receipt']],
        },
      },
    ],
    parameter_format: 'POSITIONAL',
  },
  {
    id: '1469258364071127',
    name: 'discount_coupon',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        text: 'Special offer for you! Get {{discount_percentage}}% off your next purchase. Use the code below at checkout',
        type: 'BODY',
        example: {
          body_text_named_params: [
            {
              example: '30',
              param_name: 'discount_percentage',
            },
          ],
        },
      },
      {
        type: 'BUTTONS',
        buttons: [
          {
            text: 'Copy offer code',
            type: 'COPY_CODE',
            example: ['SAVE1OFF'],
          },
        ],
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'NAMED',
  },
  {
    id: '1075221534579807',
    name: 'support_callback',
    status: 'APPROVED',
    category: 'UTILITY',
    language: 'en',
    components: [
      {
        text: 'Hello {{name}},  our support team will call you regarding ticket # {{ticket_id}}.',
        type: 'BODY',
        example: {
          body_text_named_params: [
            {
              example: 'muhsin',
              param_name: 'name',
            },
            {
              example: '232323',
              param_name: 'ticket_id',
            },
          ],
        },
      },
      {
        type: 'BUTTONS',
        buttons: [
          {
            text: 'Call Support',
            type: 'PHONE_NUMBER',
            phone_number: '+2112121212',
          },
        ],
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'NAMED',
  },
  {
    id: '1023596726651144',
    name: 'training_video',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        type: 'HEADER',
        format: 'VIDEO',
        example: {
          header_handle: [
            'https://scontent.whatsapp.net/v/t61.29466-34/521582686_1023596729984477_1872358575355618432_n.mp4',
          ],
        },
      },
      {
        text: "Hi {{name}}, here's your training video. Please watch by{{date}}.",
        type: 'BODY',
        example: {
          body_text_named_params: [
            {
              example: 'john',
              param_name: 'name',
            },
            {
              example: 'July 31',
              param_name: 'date',
            },
          ],
        },
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'NAMED',
  },
  {
    id: '1106685194739985',
    name: 'order_confirmation',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        type: 'HEADER',
        format: 'IMAGE',
        example: {
          header_handle: ['https://vite-five-phi.vercel.app/vaporfly.png'],
        },
      },
      {
        text: 'Hi your order {{1}} is confirmed. Please wait for further updates',
        type: 'BODY',
        example: {
          body_text: [['blue canvas shoes']],
        },
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'POSITIONAL',
  },
  {
    id: '1242180011253003',
    name: 'product_launch',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        type: 'HEADER',
        format: 'IMAGE',
        example: {
          header_handle: ['https://vite-five-phi.vercel.app/coat.png'],
        },
      },
      {
        text: 'New arrival! Our stunning coat now available in {{color}} color.',
        type: 'BODY',
        example: {
          body_text_named_params: [
            {
              example: 'blue',
              param_name: 'color',
            },
          ],
        },
      },
      {
        text: 'Free shipping on orders over $100. Limited time offer.',
        type: 'FOOTER',
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'NAMED',
  },
  {
    id: '1449876326175680',
    name: 'technician_visit',
    status: 'APPROVED',
    category: 'UTILITY',
    language: 'en_US',
    components: [
      {
        text: 'Technician visit',
        type: 'HEADER',
        format: 'TEXT',
      },
      {
        text: "Hi {{1}}, we're scheduling a technician visit to {{2}} on {{3}} between {{4}} and {{5}}. Please confirm if this time slot works for you.",
        type: 'BODY',
        example: {
          body_text: [
            ['John', '123 Maple St', '2025-12-31', '10:00 AM', '2:00 PM'],
          ],
        },
      },
      {
        type: 'BUTTONS',
        buttons: [
          {
            text: 'Confirm',
            type: 'QUICK_REPLY',
          },
          {
            text: 'Reschedule',
            type: 'QUICK_REPLY',
          },
        ],
      },
    ],
    parameter_format: 'POSITIONAL',
  },
  {
    id: '997298832221901',
    name: 'greet',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        text: 'Hey {{customer_name}} how may I help you?',
        type: 'BODY',
        example: {
          body_text_named_params: [
            {
              example: 'John',
              param_name: 'customer_name',
            },
          ],
        },
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'NAMED',
  },
  {
    id: '632315222954611',
    name: 'hello_world',
    status: 'APPROVED',
    category: 'UTILITY',
    language: 'en_US',
    components: [
      {
        text: 'Hello World',
        type: 'HEADER',
        format: 'TEXT',
      },
      {
        text: 'Welcome and congratulations!! This message demonstrates your ability to send a WhatsApp message notification from the Cloud API, hosted by Meta. Thank you for taking the time to test with us.',
        type: 'BODY',
      },
      {
        text: 'WhatsApp Business Platform sample message',
        type: 'FOOTER',
      },
    ],
    parameter_format: 'POSITIONAL',
  },
  {
    id: '787864066907971',
    name: 'feedback_request',
    status: 'APPROVED',
    category: 'MARKETING',
    language: 'en',
    components: [
      {
        text: "Hey {{name}}, how was your experience with Puma? We'd love your feedback!",
        type: 'BODY',
        example: {
          body_text_named_params: [
            {
              example: 'muhsin',
              param_name: 'name',
            },
          ],
        },
      },
      {
        type: 'BUTTONS',
        buttons: [
          {
            url: 'https://feedback.example.com/survey',
            text: 'Leave Feedback',
            type: 'URL',
          },
        ],
      },
    ],
    sub_category: 'CUSTOM',
    parameter_format: 'NAMED',
  },
  {
    id: '1938057163677205',
    name: 'address_update',
    status: 'APPROVED',
    category: 'UTILITY',
    language: 'en_US',
    components: [
      {
        text: 'Address update',
        type: 'HEADER',
        format: 'TEXT',
      },
      {
        text: 'Hi {{1}}, your delivery address has been successfully updated to {{2}}. Contact {{3}} for any inquiries.',
        type: 'BODY',
        example: {
          body_text: [['John', '123 Main St', 'support@telco.com']],
        },
      },
    ],
    parameter_format: 'POSITIONAL',
  },
  {
    id: '1644094842949394',
    name: 'delivery_confirmation',
    status: 'APPROVED',
    category: 'UTILITY',
    language: 'en_US',
    components: [
      {
        text: '{{1}}, your order was successfully delivered on {{2}}.\\n\\nThank you for your purchase.\\n',
        type: 'BODY',
        example: {
          body_text: [['John', 'Jan 1, 2024']],
        },
      },
    ],
    parameter_format: 'POSITIONAL',
  },
];

// Helper function to get variable values from examples
export const getWhatsAppVariables = template => {
  const variables = {};
  template.components?.forEach(component => {
    if (component.example?.body_text_named_params) {
      component.example.body_text_named_params.forEach(param => {
        variables[param.param_name] = param.example;
      });
    }
    if (component.example?.body_text) {
      component.example.body_text[0]?.forEach((value, index) => {
        variables[(index + 1).toString()] = value;
      });
    }
  });
  return variables;
};
