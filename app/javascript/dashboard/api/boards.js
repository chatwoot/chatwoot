import ApiClient from './ApiClient';

class BoardsAPI extends ApiClient {
  constructor() {
    super('sales_pipelines/boards', { accountScoped: true });
  }
}

export default new BoardsAPI();
