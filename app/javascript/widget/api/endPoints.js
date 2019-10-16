const sendMessage = (inboxId, accountId, contactId, content) => ({
  url: '/v1/widget/messages/create_incoming.json',
  params: {
    message: {
      account_id: accountId,
      inbox_id: inboxId,
      contact_id: contactId,
      content,
    },
  },
});

const getConversation = conversationId => ({
  url: `/v1/conversations/${conversationId}/get_messages.json`,
});

const createContact = (inboxId, accountId) => ({
  url: '/v1/contacts.json',
  params: {
    account_id: accountId,
    inbox_id: inboxId,
  },
});

export default {
  createContact,
  sendMessage,
  getConversation,
};
