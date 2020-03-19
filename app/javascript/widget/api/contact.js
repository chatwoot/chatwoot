import authEndPoint from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export const updateMessage = async ({ messageId, values, email }) => {
  const urlData = authEndPoint.updateMessage(messageId);
  const result = await API.patch(urlData.url, {
    contact: { email },
    message: { submitted_values: values },
  });
  return result;
};
