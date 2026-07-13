/* global axios */
import ApiClient from './ApiClient';

class InternalTasksAPI extends ApiClient {
  constructor() {
    super('internal_tasks', { accountScoped: true });
  }

  getByConversation(conversationId) {
    return axios.get(
      `${this.baseUrl()}/conversations/${conversationId}/internal_tasks`
    );
  }

  createForConversation(conversationId, payload) {
    return axios.post(
      `${this.baseUrl()}/conversations/${conversationId}/internal_tasks`,
      { internal_task: payload }
    );
  }

  getTimeline(conversationId) {
    return axios.get(
      `${this.baseUrl()}/conversations/${conversationId}/timeline`
    );
  }

  getTasks(params = {}) {
    return axios.get(this.url, { params });
  }

  get(id) {
    return axios.get(`${this.url}/${id}`);
  }

  claim(id) {
    return axios.post(`${this.url}/${id}/claim`);
  }

  start(id) {
    return axios.post(`${this.url}/${id}/start`);
  }

  complete(id, payload = {}) {
    return axios.post(`${this.url}/${id}/complete`, payload);
  }

  update(id, payload) {
    return axios.patch(`${this.url}/${id}`, { internal_task: payload });
  }

  addComment(id, comment) {
    return axios.post(`${this.url}/${id}/comment`, { comment });
  }
}

export default new InternalTasksAPI();
