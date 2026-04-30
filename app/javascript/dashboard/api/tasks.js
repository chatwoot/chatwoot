/* global axios */
import ApiClient from './ApiClient';

export const buildTaskParams = (page, sortAttr, search) => {
  let params = `page=${page}&sort=${sortAttr}`;
  if (search) {
    params = `${params}&q=${search}`;
  }
  return params;
};

class TasksAPI extends ApiClient {
  constructor() {
    super('tasks', { accountScoped: true });
  }

  get(page = 1, sortAttr = '-created_at') {
    return axios.get(`${this.url}?${buildTaskParams(page, sortAttr, '')}`);
  }

  search(search = '', page = 1, sortAttr = '-created_at') {
    return axios.get(
      `${this.url}/search?${buildTaskParams(page, sortAttr, search)}`
    );
  }

  filter(filters = {}, page = 1, sortAttr = '-created_at') {
    return axios.post(
      `${this.url}/filter?${buildTaskParams(page, sortAttr, '')}`,
      filters
    );
  }

  create(taskData) {
    return axios.post(this.url, taskData);
  }

  update(id, taskData) {
    return axios.patch(`${this.url}/${id}`, taskData);
  }

  execute(id) {
    return axios.post(`${this.url}/${id}/execute`);
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }
}

export default new TasksAPI();
