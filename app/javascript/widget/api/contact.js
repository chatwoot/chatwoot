import authEndPoint from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export const updateContact = async ({ messageId, email }) => {
  const urlData = authEndPoint.updateContact(messageId);
  const result = await API.patch(urlData.url, {
    contact: { email },
  });
  return result;
};
