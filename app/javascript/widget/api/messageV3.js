import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export default {
  create: async (content, replyTo = null, echoId = null) => {
    const urlData = endPoints.sendMessage(content, replyTo, echoId);
    return API.post(urlData.url, urlData.params);
  },

  createAttachment: async (attachment, replyTo = null, echoId = null) => {
    const urlData = endPoints.sendAttachment({ attachment, replyTo, echoId });
    return API.post(urlData.url, urlData.params);
  },

  update: ({ messageId, email, values }) => {
    const urlData = endPoints.updateMessage(messageId);
    return API.patch(urlData.url, {
      contact: { email },
      message: { submitted_values: values },
    });
  },
};
