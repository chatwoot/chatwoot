<script setup>
import TemplatePreview from './TemplatePreview.vue';

// WhatsApp Templates from whatsapp-templates.json
const whatsAppTemplates = [
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
        text: '🎉 Special offer for you! Get {{discount_percentage}}% off your next purchase. Use the code below at checkout',
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
            phone_number: '+16506677566',
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

// Twilio Templates from twillio-templates.json
const twilioTemplates = [
  {
    body: '👟 Introducing our latest release — the {{1}}! Available now for just {{2}}. Be among the first to own this style. Limited stock available!',
    types: {
      'twilio/media': {
        body: '👟 Introducing our latest release — the {{1}}! Available now for just {{2}}. Be among the first to own this style. Limited stock available!',
        media: ['https://vite-five-phi.vercel.app/jordan-shoes.jpg'],
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {
      1: 'Jordan',
      2: '100$',
    },
    content_sid: 'HX4b1ff075f097ccdf7f274b6af4d7be02',
    friendly_name: 'shoe_launch',
    template_type: 'media',
  },
  {
    body: '👟 Introducing our latest release — the {{1}}! Available now for just {{2}}. Be among the first to own this style. Limited stock available!',
    types: {
      'twilio/media': {
        body: '👟 Introducing our latest release — the {{1}}! Available now for just {{2}}. Be among the first to own this style. Limited stock available!',
        media: ['https://vite-five-phi.vercel.app/jordan-shoes.jpg'],
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {
      1: 'Jordan',
      2: '400$',
      3: 'jordan-shoes.jpg',
    },
    content_sid: 'HXd5c1f8f8d68976f841c440d5e4b46c2e',
    friendly_name: 'product_launch_custom_price',
    template_type: 'media',
  },
  {
    body: '👟 Introducing our latest release — the Nike Air Force! Available now for just $129.99',
    types: {
      'twilio/media': {
        body: '👟 Introducing our latest release — the Nike Air Force! Available now for just $129.99',
        media: ['https://vite-five-phi.vercel.app/jordan-shoes.jpg'],
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {
      3: 'jordan-shoes.jpg',
    },
    content_sid: 'HX25f6e823f2416ca4b34254d98e916fae',
    friendly_name: 'product_launch',
    template_type: 'media',
  },
  {
    body: 'Hey {{1}}, how may I help you?',
    types: {
      'twilio/text': {
        body: 'Hey {{1}}, how may I help you?',
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {
      1: 'John',
    },
    content_sid: 'HXee240fd3a8b5045dba057feda5173e55',
    friendly_name: 'greet',
    template_type: 'text',
  },
  {
    body: "Hi {{1}} Thanks for placing an order with us. We'll let you know once your order has been processed and delivered. Your order number is {{3}}. Thanks",
    types: {
      'twilio/text': {
        body: "Hi {{1}} Thanks for placing an order with us. We'll let you know once your order has been processed and delivered. Your order number is {{3}}. Thanks",
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {
      1: 'John',
      3: '12345',
    },
    content_sid: 'HX88291ef8d30d7dcd436cbb9b21c236f4',
    friendly_name: 'order_status',
    template_type: 'text',
  },
  {
    body: 'Welcome and congratulations!! This message demonstrates your ability to send a WhatsApp message notification from the Cloud API, hosted by Meta. Thank you for taking the time to test with us.',
    types: {
      'twilio/text': {
        body: 'Welcome and congratulations!! This message demonstrates your ability to send a WhatsApp message notification from the Cloud API, hosted by Meta. Thank you for taking the time to test with us.',
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {},
    content_sid: 'HXdc6da32d489ee80f67c07d5bb0e7e390',
    friendly_name: 'hello_world',
    template_type: 'text',
  },
  {
    body: 'Thanks for reaching out to us. Before we proceed, we would like to get some information from you to assist you better. To whom would you like to connect?',
    types: {
      'twilio/quick-reply': {
        body: 'Thanks for reaching out to us. Before we proceed, we would like to get some information from you to assist you better. To whom would you like to connect?',
        actions: [
          {
            id: 'Sales_payload',
            title: 'Sales',
          },
          {
            id: 'Support_payload',
            title: 'Support',
          },
        ],
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en_US',
    variables: {},
    content_sid: 'HX778677f5867f96175ab4b7efb9a5bee6',
    friendly_name: 'welcome_message_new',
    template_type: 'quick_reply',
  },
  {
    body: 'What type of Chatwoot installation are you using? Select "Chatwoot Cloud" if you are using app.chatwoot.com, otherwise select "Self-hosted Chatwoot".',
    types: {
      'twilio/quick-reply': {
        body: 'What type of Chatwoot installation are you using? Select "Chatwoot Cloud" if you are using app.chatwoot.com, otherwise select "Self-hosted Chatwoot".',
        actions: [
          {
            id: 'Chatwoot Cloud_payload',
            title: 'Chatwoot Cloud',
          },
          {
            id: 'Self-hosted Chatwoot_payload',
            title: 'Self-hosted Chatwoot',
          },
        ],
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en_US',
    variables: {},
    content_sid: 'HX3a35e5cd76529fd91d19341deb4ef685',
    friendly_name: 'saas_whatsapp_question',
    template_type: 'quick_reply',
  },
  {
    body: 'Thanks for reaching out to us. Happy to help. What are you looking for?',
    types: {
      'twilio/quick-reply': {
        body: 'Thanks for reaching out to us. Happy to help. What are you looking for?',
        actions: [
          {
            id: 'Support_payload',
            title: 'Support',
          },
          {
            id: 'Sales_payload',
            title: 'Sales',
          },
          {
            id: 'Demo_payload',
            title: 'Demo',
          },
        ],
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en_US',
    variables: {},
    content_sid: 'HX5d8e09f96cee2f7fb7bab223c03cb0a1',
    friendly_name: 'welcome_message',
    template_type: 'quick_reply',
  },
];

// Helper function to get variable values from examples
const getWhatsAppVariables = template => {
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
</script>

<template>
  <Story
    title="Components/TemplatePreviewExamples"
    :layout="{ type: 'grid', width: 400 }"
  >
    <!-- WhatsApp Templates -->
    <Variant title="WA: Event Invitation (Buttons)">
      <TemplatePreview
        :template="whatsAppTemplates[0]"
        :variables="getWhatsAppVariables(whatsAppTemplates[0])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Purchase Receipt (Document)">
      <TemplatePreview
        :template="whatsAppTemplates[1]"
        :variables="getWhatsAppVariables(whatsAppTemplates[1])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Discount Coupon (Copy Code)">
      <TemplatePreview
        :template="whatsAppTemplates[2]"
        :variables="getWhatsAppVariables(whatsAppTemplates[2])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Support Callback (Phone)">
      <TemplatePreview
        :template="whatsAppTemplates[3]"
        :variables="getWhatsAppVariables(whatsAppTemplates[3])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Training Video (Video)">
      <TemplatePreview
        :template="whatsAppTemplates[4]"
        :variables="getWhatsAppVariables(whatsAppTemplates[4])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Order Confirmation (Image)">
      <TemplatePreview
        :template="whatsAppTemplates[5]"
        :variables="getWhatsAppVariables(whatsAppTemplates[5])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Product Launch (Image + Footer)">
      <TemplatePreview
        :template="whatsAppTemplates[6]"
        :variables="getWhatsAppVariables(whatsAppTemplates[6])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Technician Visit (Header + Buttons)">
      <TemplatePreview
        :template="whatsAppTemplates[7]"
        :variables="getWhatsAppVariables(whatsAppTemplates[7])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Greet (Simple Text)">
      <TemplatePreview
        :template="whatsAppTemplates[8]"
        :variables="getWhatsAppVariables(whatsAppTemplates[8])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Hello World (Header + Footer)">
      <TemplatePreview
        :template="whatsAppTemplates[9]"
        :variables="getWhatsAppVariables(whatsAppTemplates[9])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Feedback Request (Button)">
      <TemplatePreview
        :template="whatsAppTemplates[10]"
        :variables="getWhatsAppVariables(whatsAppTemplates[10])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Address Update (Header)">
      <TemplatePreview
        :template="whatsAppTemplates[11]"
        :variables="getWhatsAppVariables(whatsAppTemplates[11])"
        platform="whatsapp"
      />
    </Variant>

    <Variant title="WA: Delivery Confirmation">
      <TemplatePreview
        :template="whatsAppTemplates[12]"
        :variables="getWhatsAppVariables(whatsAppTemplates[12])"
        platform="whatsapp"
      />
    </Variant>

    <!-- Twilio Templates -->
    <Variant title="Twilio: Shoe Launch (Media)">
      <TemplatePreview
        :template="twilioTemplates[0]"
        :variables="twilioTemplates[0].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Product Launch Custom Price (Media)">
      <TemplatePreview
        :template="twilioTemplates[1]"
        :variables="twilioTemplates[1].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Product Launch (Media)">
      <TemplatePreview
        :template="twilioTemplates[2]"
        :variables="twilioTemplates[2].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Greet (Text)">
      <TemplatePreview
        :template="twilioTemplates[3]"
        :variables="twilioTemplates[3].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Order Status (Text)">
      <TemplatePreview
        :template="twilioTemplates[4]"
        :variables="twilioTemplates[4].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Hello World (Text)">
      <TemplatePreview
        :template="twilioTemplates[5]"
        :variables="twilioTemplates[5].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Welcome Message New (Quick Reply)">
      <TemplatePreview
        :template="twilioTemplates[6]"
        :variables="twilioTemplates[6].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: SaaS WhatsApp Question (Quick Reply)">
      <TemplatePreview
        :template="twilioTemplates[7]"
        :variables="twilioTemplates[7].variables"
        platform="twilio"
      />
    </Variant>

    <Variant title="Twilio: Welcome Message (Quick Reply)">
      <TemplatePreview
        :template="twilioTemplates[8]"
        :variables="twilioTemplates[8].variables"
        platform="twilio"
      />
    </Variant>
  </Story>
</template>
