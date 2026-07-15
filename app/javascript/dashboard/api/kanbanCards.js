/* global axios */

import ApiClient from './ApiClient';

class KanbanCardsAPI extends ApiClient {
  constructor() {
    super('kanban_boards', { accountScoped: true });
  }

  get({ boardId }) {
    return axios.get(`${this.url}/${boardId}/kanban_cards`);
  }

  create({ boardId, card }) {
    return axios.post(`${this.url}/${boardId}/kanban_cards`, card);
  }

  update({ boardId, cardId, card }) {
    return axios.patch(`${this.url}/${boardId}/kanban_cards/${cardId}`, card);
  }

  move({ boardId, cardId, card }) {
    return axios.patch(
      `${this.url}/${boardId}/kanban_cards/${cardId}/move`,
      card
    );
  }

  delete({ boardId, cardId }) {
    return axios.delete(`${this.url}/${boardId}/kanban_cards/${cardId}`);
  }
}

export default new KanbanCardsAPI();
