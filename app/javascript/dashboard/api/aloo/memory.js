/* global axios */
import ApiClient from '../ApiClient';

class AlooMemory extends ApiClient {
  constructor() {
    super('aloo/assistants', { accountScoped: true });
  }

  getMemories(assistantId, { page = 1, memoryType, activeOnly = false } = {}) {
    return axios.get(`${this.url}/${assistantId}/memories`, {
      params: {
        page,
        memory_type: memoryType,
        active_only: activeOnly,
      },
    });
  }

  deleteMemory(assistantId, memoryId) {
    return axios.delete(`${this.url}/${assistantId}/memories/${memoryId}`);
  }
}

export default new AlooMemory();
