/* global axios */
import ApiClient from './ApiClient';

class KanbanAPI extends ApiClient {
  constructor() {
    super('kanban', { accountScoped: true });
  }

  // Board
  getBoard() {
    return axios.get(`${this.url}/board`);
  }

  // Columns
  getColumns() {
    return axios.get(`${this.url}/columns`);
  }

  createColumn(params) {
    return axios.post(`${this.url}/columns`, { column: params });
  }

  updateColumn(id, params) {
    return axios.patch(`${this.url}/columns/${id}`, { column: params });
  }

  reorderColumns(positions) {
    return axios.patch(`${this.url}/columns/reorder`, { positions });
  }

  deleteColumn(id) {
    return axios.delete(`${this.url}/columns/${id}`);
  }

  // Cards
  getCards(columnId) {
    return axios.get(`${this.url}/columns/${columnId}/cards`);
  }

  createCard(columnId, params) {
    return axios.post(`${this.url}/columns/${columnId}/cards`, {
      card: params,
    });
  }

  updateCard(id, params) {
    return axios.patch(`${this.url}/cards/${id}`, { card: params });
  }

  moveCard(id, { columnId }) {
    return axios.patch(`${this.url}/cards/${id}/move`, { column_id: columnId });
  }

  deleteCard(id) {
    return axios.delete(`${this.url}/cards/${id}`);
  }

  // Schedules
  getSchedules(cardId) {
    return axios.get(`${this.url}/cards/${cardId}/card_schedules`);
  }

  createSchedule(cardId, params) {
    return axios.post(`${this.url}/cards/${cardId}/card_schedules`, {
      schedule: params,
    });
  }

  deleteSchedule(cardId, scheduleId) {
    return axios.delete(
      `${this.url}/cards/${cardId}/card_schedules/${scheduleId}`
    );
  }
}

export default new KanbanAPI();
