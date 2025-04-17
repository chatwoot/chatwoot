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

  getKnowledgeSources(idAgent) {
    return axios.get(`${this.url}/${idAgent}/knowledge_sources`);
  }
  
  addKnowledgeText(idAgent, data) {
    return axios.post(`${this.url}/${idAgent}/knowledge_sources/text`, {
      id: null,
      text: data.text,
      tab: data.tab,
    });
  }
  
  updateKnowledgeText(idAgent, data) {
    return axios.patch(`${this.url}/${idAgent}/knowledge_sources/text`, {
      id: data.id,
      text: data.text,
      tab: data.tab,
    });
  }
  
  deleteKnowledgeText(idAgent, textId) {
    return axios.delete(`${this.url}/${idAgent}/knowledge_sources/text/${textId}`);
  }
  
  addKnowledgeFile(idAgent, formData) {
    return axios.post(`${this.url}/${idAgent}/knowledge_sources/file`, formData);
  }
  
  deleteKnowledgeFile(idAgent, fileId) {
    return axios.delete(`${this.url}/${idAgent}/knowledge_sources/file/${fileId}`);
  }
  
  editKnowledgeWebsite(idAgent, data) {
    return axios.patch(`${this.url}/${idAgent}/knowledge_sources/website`, data);
  }
  
  deleteKnowledgeWebsite(idAgent, data) {
    return axios.delete(`${this.url}/${idAgent}/knowledge_sources/website`, {
      data: data,
    });
  }
}

export default new AiAgents();
