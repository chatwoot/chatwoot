import authEndPoint from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export default {
  update: ({ messageId, email, values }) => {
    const urlData = authEndPoint.updateMessage(messageId);
    return API.patch(urlData.url, {
      contact: { email },
      message: { submitted_values: values },
    });
  },
};
