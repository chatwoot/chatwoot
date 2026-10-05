/* global axios */
import ApiClient from '../ApiClient';

class CaptainCustomTools extends ApiClient {
  constructor() {
    super('captain/custom_tools', { accountScoped: true });
  }

  get({ assistantId, page = 1, searchKey, signal } = {}) {
    return axios.get(this.url, {
      params: { assistant_id: assistantId, page, searchKey },
      signal,
    });
  }

  show({ id, assistantId }) {
    return axios.get(`${this.url}/${id}`, {
      params: { assistant_id: assistantId },
    });
  }

  create({ assistantId, ...data } = {}) {
    return axios.post(this.url, {
      assistant_id: assistantId,
      custom_tool: data,
    });
  }

  update(id, { assistantId, ...data } = {}) {
    return axios.put(`${this.url}/${id}`, {
      assistant_id: assistantId,
      custom_tool: data,
    });
  }

  delete({ id, assistantId }) {
    return axios.delete(`${this.url}/${id}`, {
      params: { assistant_id: assistantId },
    });
  }

  test({ assistantId, ...data } = {}) {
    return axios.post(`${this.url}/test`, {
      assistant_id: assistantId,
      custom_tool: data,
    });
  }
}

export default new CaptainCustomTools();
