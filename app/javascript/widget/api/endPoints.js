const sendMessage = content => ({
  url: `/api/v1/widget/messages${window.location.search}`,
  params: {
    message: {
      content,
      timestamp: new Date().toString(),
      referer_url: window.refererURL || '',
    },
  },
});

const getConversation = ({ before }) => ({
  url: `/api/v1/widget/messages${window.location.search}`,
  params: { before },
});

const updateContact = id => ({
  url: `/api/v1/widget/messages/${id}${window.location.search}`,
});

export default {
  sendMessage,
  getConversation,
  updateContact,
};
