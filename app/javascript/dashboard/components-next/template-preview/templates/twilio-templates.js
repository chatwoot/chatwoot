export const twilioTemplates = [
  {
    body: 'Introducing our latest release  the {{1}}! Available now for just {{2}}. Be among the first to own this style. Limited stock available!',
    types: {
      'twilio/media': {
        body: 'Introducing our latest release  the {{1}}! Available now for just {{2}}. Be among the first to own this style. Limited stock available!',
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
    body: 'Introducing our latest release  the {{1}}! Available now for just {{2}}. Be among the first to own this style. Limited stock available!',
    types: {
      'twilio/media': {
        body: 'Introducing our latest release  the {{1}}! Available now for just {{2}}. Be among the first to own this style. Limited stock available!',
        media: ['https://vite-five-phi.vercel.app/jordan-shoes.jpg'],
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {
      1: 'Jordan',
      2: '400$',
    },
    content_sid: 'HXd5c1f8f8d68976f841c440d5e4b46c2e',
    friendly_name: 'product_launch_custom_price',
    template_type: 'media',
  },
  {
    body: 'Introducing our latest release  the Nike Air Force! Available now for just $129.99',
    types: {
      'twilio/media': {
        body: 'Introducing our latest release  the Nike Air Force! Available now for just $129.99',
        media: ['https://vite-five-phi.vercel.app/jordan-shoes.jpg'],
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {},
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
  {
    types: {
      'twilio/call-to-action': {
        actions: [
          {
            id: null,
            title: 'Pay now',
            type: 'URL',
            url: 'https://payments.example.com/pay',
          },
        ],
        body: 'Hello, this is a gentle reminder regarding your course fee.\n\nThe payment is due on {{date}}.\nKindly complete the payment at your convenience',
      },
    },
    status: 'approved',
    category: 'utility',
    language: 'en',
    variables: {
      date: '01-Jan-2026',
    },
    content_sid: 'HX63e56fc142aad670f320bf400d5bfeb7',
    friendly_name: 'course_fee_reminder',
    template_type: 'call_to_action',
  },
];
