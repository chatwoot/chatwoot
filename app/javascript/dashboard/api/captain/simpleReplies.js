/* global axios */
import ApiClient from '../ApiClient';

class CaptainSimpleReplies extends ApiClient {
  constructor() {
    super('captain/assistants', { accountScoped: true });
  }

  get({ assistantId, page = 1, searchKey } = {}) {
    return axios.get(`${this.url}/${assistantId}/simple_replies`, {
      params: { page, searchKey },
    });
  }

  show({ assistantId, id }) {
    return axios.get(`${this.url}/${assistantId}/simple_replies/${id}`);
  }

  create({ assistantId, ...data } = {}) {
    return axios.post(`${this.url}/${assistantId}/simple_replies`, {
      simple_reply: data,
    });
  }

  update({ assistantId, id }, data = {}) {
    return axios.put(`${this.url}/${assistantId}/simple_replies/${id}`, {
      simple_reply: data,
    });
  }

  delete({ assistantId, id }) {
    return axios.delete(`${this.url}/${assistantId}/simple_replies/${id}`);
  }
}

export default new CaptainSimpleReplies();
