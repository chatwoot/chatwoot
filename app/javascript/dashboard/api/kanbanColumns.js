/* global axios */

import ApiClient from './ApiClient';

class KanbanColumnsAPI extends ApiClient {
  constructor() {
    super('kanban_boards', { accountScoped: true });
  }

  get({ boardId }) {
    return axios.get(`${this.url}/${boardId}/kanban_columns`);
  }

  create({ boardId, column }) {
    return axios.post(`${this.url}/${boardId}/kanban_columns`, column);
  }

  update({ boardId, columnId, column }) {
    return axios.patch(
      `${this.url}/${boardId}/kanban_columns/${columnId}`,
      column
    );
  }

  delete({ boardId, columnId }) {
    return axios.delete(`${this.url}/${boardId}/kanban_columns/${columnId}`);
  }
}

export default new KanbanColumnsAPI();
