/* global axios */

import ApiClient from './ApiClient';

class AiAgents extends ApiClient {
  constructor() {
    super('ai_agents', { accountScoped: true });
  }

  getAiAgents() {
    return this.get();
  }

  createAiAgent(name, templateId) {
    return this.create({
      name,
      template_id: templateId,
    });
  }
  
  removeAiAgent(idAgent) {
    return this.delete(idAgent);
  }
}

export default new AiAgents();
