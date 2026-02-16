/* global axios */

const create = (accountId, { contactId, conversationId }) => {
  return axios.post(`/api/v1/accounts/${accountId}/storefront_links`, {
    contact_id: contactId,
    conversation_id: conversationId,
  });
};

const preview = accountId => {
  return axios.post(`/api/v1/accounts/${accountId}/storefront_links/preview`);
};

export default {
  create,
  preview,
};
