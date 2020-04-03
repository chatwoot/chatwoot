import authEndPoint from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export default {
  update: ({ messageId, email }) => {
    const urlData = authEndPoint.updateContact(messageId);
    return API.patch(urlData.url, {
      contact: { email },
    });
  },
};
