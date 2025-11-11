/* global axios */

const create = (accountId, conversationId, paymentData) => {
  return axios.post(
    `/api/v1/accounts/${accountId}/conversations/${conversationId}/payment_links`,
    paymentData
  );
};

export default {
  create,
};
