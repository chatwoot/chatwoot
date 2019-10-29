import authEndPoint from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

const createContact = async (inboxId, accountId) => {
  const urlData = authEndPoint.createContact(inboxId, accountId);
  const result = await API.post(urlData.url, urlData.params);
  return result;
};

export default {
  createContact,
};
