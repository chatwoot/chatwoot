/* global axios */
import ApiClient from './ApiClient';

class MacrosAPI extends ApiClient {
  constructor() {
    super('macros', { accountScoped: true });
  }

  executeMacro({ macroId, conversationIds }) {
    return axios.post(`${this.url}/${macroId}/execute`, {
      conversation_ids: conversationIds,
    });
  }
}

export default new MacrosAPI();
