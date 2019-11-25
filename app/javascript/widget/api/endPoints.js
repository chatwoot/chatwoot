const sendMessage = content => ({
  url: `/api/v1/widget/messages${window.location.search}`,
  params: {
    message: {
      content,
      timestamp: new Date().toString(),
      referer_url: window.parent ? window.parent.location.href : '',
    },
  },
});

const getConversation = ({ before }) => ({
  url: `/api/v1/widget/messages${window.location.search}`,
  params: { before },
});

export default {
  sendMessage,
  getConversation,
};
