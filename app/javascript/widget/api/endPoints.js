const sendMessage = content => ({
  url: `/api/v1/widget/messages${window.location.search}`,
  params: {
    message: {
      content,
    },
  },
});

const getConversation = () => ({
  url: `/api/v1/widget/messages${window.location.search}`,
});

export default {
  sendMessage,
  getConversation,
};
