/* global axios */

const send = (accountId, conversationId, productIds) => {
  return axios.post(
    `/api/v1/accounts/${accountId}/conversations/${conversationId}/catalog_items`,
    { product_ids: productIds }
  );
};

export default {
  send,
};
