import ApiClient from './ApiClient';

class KanbanBoardsAPI extends ApiClient {
  constructor() {
    super('kanban_boards', { accountScoped: true });
  }
}

export default new KanbanBoardsAPI();
