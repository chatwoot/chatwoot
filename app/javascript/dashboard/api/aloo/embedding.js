/* global axios */
import ApiClient from '../ApiClient';

class AlooEmbedding extends ApiClient {
  constructor() {
    super('aloo/assistants', { accountScoped: true });
  }

  getEmbeddings(assistantId, { page = 1, status } = {}) {
    return axios.get(`${this.url}/${assistantId}/embeddings`, {
      params: {
        page,
        status,
      },
    });
  }
}

export default new AlooEmbedding();
