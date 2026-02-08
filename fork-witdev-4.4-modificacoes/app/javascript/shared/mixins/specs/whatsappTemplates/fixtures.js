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
];
