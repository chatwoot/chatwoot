export default {
  nonDeletedMessage: {
    content: 'Hey',
    content_attributes: {},
    attachments: [
      {
        data_url: 'https://assets.com/kseb-bill.pdf',
        extension: null,
        file_type: 'file',
      },
    ],
    content_type: 'text',
    conversation_id: 1,
    created_at: 1626111625,
    id: 1,
    message_type: 0,
  },
  deletedMessage: {
    content: 'This message was deleted',
    content_attributes: { deleted: true },
    content_type: null,
    conversation_id: 1,
    created_at: 1626111634,
    id: 2,
    message_type: 1,
  },
};
