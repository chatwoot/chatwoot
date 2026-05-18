/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

class KanbanBoardsAPI extends ApiClient {
  constructor() { super('kanban/boards', { accountScoped: true }); }
  duplicate(boardId) { return axios.post(`${this.url}/${boardId}/duplicate`); }
}

class KanbanColumnsAPI extends ApiClient {
  constructor() { super('kanban/boards', { accountScoped: true }); }
  list   (b)             { return axios.get   (`${this.url}/${b}/columns`); }
  create (b, column)     { return axios.post  (`${this.url}/${b}/columns`, { column }); }
  update (b, id, column) { return axios.patch (`${this.url}/${b}/columns/${id}`, { column }); }
  destroy(b, id)         { return axios.delete(`${this.url}/${b}/columns/${id}`); }
  reorder(b, order)      { return axios.patch (`${this.url}/${b}/columns/reorder`, { order }); }
}

class KanbanCardsAPI extends ApiClient {
  constructor() { super('kanban/boards', { accountScoped: true }); }
  list   (b, params = {})        { return axios.get   (`${this.url}/${b}/cards`,         { params }); }
  create (b, card)               { return axios.post  (`${this.url}/${b}/cards`,         { card }); }
  update (b, id, card)           { return axios.patch (`${this.url}/${b}/cards/${id}`,   { card }); }
  destroy(b, id, { hard = false } = {}) {
    return axios.delete(`${this.url}/${b}/cards/${id}${hard ? '?hard=true' : ''}`);
  }
  unarchive(b, id)               { return axios.post  (`${this.url}/${b}/cards/${id}/unarchive`); }
  move   (b, { cardId, toColumnId, position }) {
    return axios.patch(`${this.url}/${b}/cards/move`, {
      card_id: cardId, to_column_id: toColumnId, position,
    });
  }
  activities (b, id)             { return axios.get   (`${this.url}/${b}/cards/${id}/activities`); }
  comments   (b, id)             { return axios.get   (`${this.url}/${b}/cards/${id}/comments`); }
  addComment (b, id, content)    { return axios.post  (`${this.url}/${b}/cards/${id}/comments`, { comment: { content } }); }
  delComment (b, id, commentId)  { return axios.delete(`${this.url}/${b}/cards/${id}/comments/${commentId}`); }
  checklist  (b, id)             { return axios.get   (`${this.url}/${b}/cards/${id}/checklist`); }
  addChecklistItem(b, id, title) {
    return axios.post(`${this.url}/${b}/cards/${id}/checklist`, { checklist_item: { title } });
  }
  toggleChecklistItem(b, id, itemId) {
    return axios.patch(`${this.url}/${b}/cards/${id}/checklist/${itemId}/toggle`);
  }
  delChecklistItem(b, id, itemId) {
    return axios.delete(`${this.url}/${b}/cards/${id}/checklist/${itemId}`);
  }
  assignLabel  (b, id, labelId)  { return axios.post  (`${this.url}/${b}/cards/${id}/labels/${labelId}`); }
  unassignLabel(b, id, labelId)  { return axios.delete(`${this.url}/${b}/cards/${id}/labels/${labelId}`); }
}

class KanbanLabelsAPI extends ApiClient {
  constructor() { super('kanban/labels', { accountScoped: true }); }
}

export const KanbanBoards  = new KanbanBoardsAPI();
export const KanbanColumns = new KanbanColumnsAPI();
export const KanbanCards   = new KanbanCardsAPI();
export const KanbanLabels  = new KanbanLabelsAPI();
