export const mockConversations = [
  {
    id: 1,
    messages: [
      {
        id: 101,
        content: 'Hello, how can I assist you today?',
      },
      {
        id: 102,
        content: 'I need help with my order.',
        content_attributes: {
          deleted: true,
        },
      },
    ],
    status: 'open',
  },
  {
    id: 2,
    messages: [
      {
        id: 201,
        content: 'Good morning, what can I do for you?',
      },
    ],
    status: 'open',
  },
];
