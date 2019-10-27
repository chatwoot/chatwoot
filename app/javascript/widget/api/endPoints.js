const sendMessage = content => ({
  url: '/api/v1/widget/messages',
  params: {
    message: {
      content,
    },
  },
});

const getConversation = () => ({
  url: `/api/v1/widget/messages`,
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
