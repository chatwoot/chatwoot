/* global axios */

const getAll = (accountId, orderId) => {
  return axios.get(
    `/api/v1/accounts/${accountId}/orders/${orderId}/order_notes`
  );
};

const create = (accountId, orderId, content) => {
  return axios.post(
    `/api/v1/accounts/${accountId}/orders/${orderId}/order_notes`,
    { order_note: { content } }
  );
};

const destroy = (accountId, orderId, noteId) => {
  return axios.delete(
    `/api/v1/accounts/${accountId}/orders/${orderId}/order_notes/${noteId}`
  );
};

export default {
  getAll,
  create,
  destroy,
};
