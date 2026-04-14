export const templates = [
  {
    name: 'sample_flight_confirmation',
    status: 'approved',
    category: 'TICKET_UPDATE',
    language: 'pt_BR',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      { type: 'HEADER', format: 'DOCUMENT' },
      {
        text: 'Esta é a sua confirmação de voo para {{1}}-{{2}} em {{3}}.',
        type: 'BODY',
      },
      {
        text: 'Esta mensagem é de uma empresa não verificada.',
        type: 'FOOTER',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'sample_issue_resolution',
    status: 'approved',
    category: 'ISSUE_RESOLUTION',
    language: 'pt_BR',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'Oi, {{1}}. Nós conseguimos resolver o problema que você estava enfrentando?',
        type: 'BODY',
      },
      {
        text: 'Esta mensagem é de uma empresa não verificada.',
        type: 'FOOTER',
      },
      {
        type: 'BUTTONS',
        buttons: [
          { text: 'Sim', type: 'QUICK_REPLY' },
          { text: 'Não', type: 'QUICK_REPLY' },
        ],
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'sample_issue_resolution',
    status: 'approved',
    category: 'ISSUE_RESOLUTION',
    language: 'es',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'Hola, {{1}}. ¿Pudiste solucionar el problema que tenías?',
        type: 'BODY',
      },
      {
        text: 'Este mensaje proviene de un negocio no verificado.',
        type: 'FOOTER',
      },
      {
        type: 'BUTTONS',
        buttons: [
          { text: 'Sí', type: 'QUICK_REPLY' },
          { text: 'No', type: 'QUICK_REPLY' },
        ],
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'sample_issue_resolution',
    status: 'approved',
    category: 'ISSUE_RESOLUTION',
    language: 'id',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'Halo {{1}}, apakah kami bisa mengatasi masalah yang sedang Anda hadapi?',
        type: 'BODY',
      },
      {
        text: 'Pesan ini berasal dari bisnis yang tidak terverifikasi.',
        type: 'FOOTER',
      },
      {
        type: 'BUTTONS',
        buttons: [
          { text: 'Ya', type: 'QUICK_REPLY' },
          { text: 'Tidak', type: 'QUICK_REPLY' },
        ],
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'sample_shipping_confirmation',
    status: 'approved',
    category: 'SHIPPING_UPDATE',
    language: 'pt_BR',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'Seu pacote foi enviado. Ele será entregue em {{1}} dias úteis.',
        type: 'BODY',
      },
      {
        text: 'Esta mensagem é de uma empresa não verificada.',
        type: 'FOOTER',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'sample_shipping_confirmation',
    status: 'approved',
    category: 'SHIPPING_UPDATE',
    language: 'id',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'Paket Anda sudah dikirim. Paket akan sampai dalam {{1}} hari kerja.',
        type: 'BODY',
      },
      {
        text: 'Pesan ini berasal dari bisnis yang tidak terverifikasi.',
        type: 'FOOTER',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'sample_shipping_confirmation',
    status: 'approved',
    category: 'SHIPPING_UPDATE',
    language: 'es',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'ó tu paquete. La entrega se realizará en {{1}} dí.',
        type: 'BODY',
      },
      {
        text: 'Este mensaje proviene de un negocio no verificado.',
        type: 'FOOTER',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'sample_flight_confirmation',
    status: 'approved',
    category: 'TICKET_UPDATE',
    language: 'id',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      { type: 'HEADER', format: 'DOCUMENT' },
      {
        text: 'Ini merupakan konfirmasi penerbangan Anda untuk {{1}}-{{2}} di {{3}}.',
        type: 'BODY',
      },
      {
        text: 'Pesan ini berasal dari bisnis yang tidak terverifikasi.',
        type: 'FOOTER',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'sample_issue_resolution',
    status: 'approved',
    category: 'ISSUE_RESOLUTION',
    language: 'en_US',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'Hi {{1}}, were we able to solve the issue that you were facing?',
        type: 'BODY',
      },
      { text: 'This message is from an unverified business.', type: 'FOOTER' },
      {
        type: 'BUTTONS',
        buttons: [
          { text: 'Yes', type: 'QUICK_REPLY' },
          { text: 'No', type: 'QUICK_REPLY' },
        ],
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'sample_flight_confirmation',
    status: 'approved',
    category: 'TICKET_UPDATE',
    language: 'es',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      { type: 'HEADER', format: 'DOCUMENT' },
      {
        text: 'Confirmamos tu vuelo a {{1}}-{{2}} para el {{3}}.',
        type: 'BODY',
      },
      {
        text: 'Este mensaje proviene de un negocio no verificado.',
        type: 'FOOTER',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'sample_flight_confirmation',
    status: 'approved',
    category: 'TICKET_UPDATE',
    language: 'en_US',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      { type: 'HEADER', format: 'DOCUMENT' },
      {
        text: 'This is your flight confirmation for {{1}}-{{2}} on {{3}}.',
        type: 'BODY',
      },
      { text: 'This message is from an unverified business.', type: 'FOOTER' },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'sample_shipping_confirmation',
    status: 'approved',
    category: 'SHIPPING_UPDATE',
    language: 'en_US',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'Your package has been shipped. It will be delivered in {{1}} business days.',
        type: 'BODY',
      },
      { text: 'This message is from an unverified business.', type: 'FOOTER' },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'no_variable_template',
    status: 'approved',
    category: 'TICKET_UPDATE',
    language: 'pt_BR',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        type: 'HEADER',
        format: 'DOCUMENT',
      },
      {
        text: 'This is a test whatsapp template',
        type: 'BODY',
      },
      {
        text: 'Esta mensagem é de uma empresa não verificada.',
        type: 'FOOTER',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'order_confirmation',
    status: 'approved',
    category: 'TICKET_UPDATE',
    language: 'en_US',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        type: 'HEADER',
        format: 'IMAGE',
        example: {
          header_handle: ['https://example.com/shoes.jpg'],
        },
      },
      {
        text: 'Hi your order {{1}} is confirmed. Please wait for further updates',
        type: 'BODY',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'technician_visit',
    status: 'approved',
    category: 'UTILITY',
    language: 'en_US',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'Technician visit',
        type: 'HEADER',
        format: 'TEXT',
      },
      {
        text: "Hi {{1}}, we're scheduling a technician visit to {{2}} on {{3}} between {{4}} and {{5}}. Please confirm if this time slot works for you.",
        type: 'BODY',
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
    rejected_reason: 'NONE',
  },
  {
    name: 'event_invitation_static',
    status: 'approved',
    category: 'MARKETING',
    language: 'en',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: "You're invited to {{event_name}} at {{location}}, Join us for an amazing experience!",
        type: 'BODY',
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
    rejected_reason: 'NONE',
  },
  {
    name: 'purchase_receipt',
    status: 'approved',
    category: 'UTILITY',
    language: 'en_US',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        type: 'HEADER',
        format: 'DOCUMENT',
      },
      {
        text: 'Thank you for using your {{1}} card at {{2}}. Your {{3}} is attached as a PDF.',
        type: 'BODY',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'discount_coupon',
    status: 'approved',
    category: 'MARKETING',
    language: 'en',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: '🎉 Special offer for you! Get {{discount_percentage}}% off your next purchase. Use the code below at checkout',
        type: 'BODY',
      },
      {
        type: 'BUTTONS',
        buttons: [
          {
            text: 'Copy offer code',
            type: 'COPY_CODE',
          },
        ],
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'support_callback',
    status: 'approved',
    category: 'UTILITY',
    language: 'en',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'Hello {{name}}, our support team will call you regarding ticket # {{ticket_id}}.',
        type: 'BODY',
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
    rejected_reason: 'NONE',
  },
  {
    name: 'training_video',
    status: 'approved',
    category: 'MARKETING',
    language: 'en',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        type: 'HEADER',
        format: 'VIDEO',
      },
      {
        text: "Hi {{name}}, here's your training video. Please watch by{{date}}.",
        type: 'BODY',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'product_launch',
    status: 'approved',
    category: 'MARKETING',
    language: 'en',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        type: 'HEADER',
        format: 'IMAGE',
      },
      {
        text: 'New arrival! Our stunning coat now available in {{color}} color.',
        type: 'BODY',
      },
      {
        text: 'Free shipping on orders over $100. Limited time offer.',
        type: 'FOOTER',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'greet',
    status: 'approved',
    category: 'MARKETING',
    language: 'en',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'Hey {{customer_name}} how may I help you?',
        type: 'BODY',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'hello_world',
    status: 'approved',
    category: 'UTILITY',
    language: 'en_US',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
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
    rejected_reason: 'NONE',
  },
  {
    name: 'feedback_request',
    status: 'approved',
    category: 'MARKETING',
    language: 'en',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: "Hey {{name}}, how was your experience with Puma? We'd love your feedback!",
        type: 'BODY',
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
    rejected_reason: 'NONE',
  },
  {
    name: 'address_update',
    status: 'approved',
    category: 'UTILITY',
    language: 'en_US',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: 'Address update',
        type: 'HEADER',
        format: 'TEXT',
      },
      {
        text: 'Hi {{1}}, your delivery address has been successfully updated to {{2}}. Contact {{3}} for any inquiries.',
        type: 'BODY',
      },
    ],
    rejected_reason: 'NONE',
  },
  {
    name: 'delivery_confirmation',
    status: 'approved',
    category: 'UTILITY',
    language: 'en_US',
    namespace: 'ed41a221_133a_4558_a1d6_192960e3aee9',
    components: [
      {
        text: '{{1}}, your order was successfully delivered on {{2}}.\n\nThank you for your purchase.\n',
        type: 'BODY',
      },
    ],
    rejected_reason: 'NONE',
  },
];
