/* global axios */
import ApiClient from '../ApiClient';

class CaptainWorkflows extends ApiClient {
  constructor() {
    super('captain/assistants', { accountScoped: true });
  }

  get({ assistantId, page = 1 } = {}) {
    return axios.get(`${this.url}/${assistantId}/workflows`, {
      params: { page },
    });
  }

  show({ assistantId, id }) {
    return axios.get(`${this.url}/${assistantId}/workflows/${id}`);
  }

  create({ assistantId, ...data } = {}) {
    return axios.post(`${this.url}/${assistantId}/workflows`, {
      workflow: data,
    });
  }

  update({ assistantId, id }, data = {}) {
    return axios.put(`${this.url}/${assistantId}/workflows/${id}`, {
      workflow: data,
    });
  }

  delete({ assistantId, id }) {
    return axios.delete(`${this.url}/${assistantId}/workflows/${id}`);
  }

  executions({ assistantId, id }) {
    return axios.get(`${this.url}/${assistantId}/workflows/${id}/executions`);
  }
}

export default new CaptainWorkflows();
