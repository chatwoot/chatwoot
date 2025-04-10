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

  detailAgent(idAgent) {
    return this.show(idAgent);
  }

  updateAgent(idAgent, data) {
    return this.update(idAgent, data);
  }

  listAiTemplate() {
    return axios.get(`${this.url}/ai_agent_templates`);
  }

  updateAgentFollowups(idAgent, data) {
    return axios.patch(`${this.url}/${idAgent}/update_followups`, data);
  }
}

export default new AiAgents();
