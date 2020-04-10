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

const sendAttachmnet = ({ attachment }) => {
  const { refererURL = '' } = window;
  const timestamp = new Date().toString();
  const { file, file_type: fileType } = attachment;

  const formData = new FormData();
  formData.append('message[attachment][file]', file);
  formData.append('message[attachment][file_type]', fileType);
  formData.append('message[referer_url]', refererURL);
  formData.append('message[timestamp]', timestamp);
  return {
    url: `/api/v1/widget/messages${window.location.search}`,
    params: formData,
  };
};

const getConversation = ({ before }) => ({
  url: `/api/v1/widget/messages${window.location.search}`,
  params: { before },
});

const updateMessage = id => ({
  url: `/api/v1/widget/messages/${id}${window.location.search}`,
});

const getAvailableAgents = token => ({
  url: '/api/v1/widget/inbox_members',
  params: {
    website_token: token,
  },
});

export default {
  sendMessage,
  sendAttachmnet,
  getConversation,
  updateMessage,
  getAvailableAgents,
};
