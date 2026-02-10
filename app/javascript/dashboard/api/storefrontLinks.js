/* global axios */

const create = (accountId, { contactId, conversationId }) => {
  return axios.post(`/api/v1/accounts/${accountId}/storefront_links`, {
    contact_id: contactId,
    conversation_id: conversationId,
  });
};

export default {
  create,
};
