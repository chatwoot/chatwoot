/* global axios */
import ApiClient from '../ApiClient';

class AiAgentsAPI extends ApiClient {
  constructor() {
    super('ai_agents', { accountScoped: true, saas: true });
  }

  getKnowledgeBases(agentId) {
    return axios.get(`${this.url}/${agentId}/knowledge_bases`);
  }

  getKnowledgeBase(agentId, kbId) {
    return axios.get(`${this.url}/${agentId}/knowledge_bases/${kbId}`);
  }

  createKnowledgeBase(agentId, data) {
    return axios.post(`${this.url}/${agentId}/knowledge_bases`, {
      knowledge_base: data,
    });
  }

  updateKnowledgeBase(agentId, kbId, data) {
    return axios.patch(`${this.url}/${agentId}/knowledge_bases/${kbId}`, {
      knowledge_base: data,
    });
  }

  deleteKnowledgeBase(agentId, kbId) {
    return axios.delete(`${this.url}/${agentId}/knowledge_bases/${kbId}`);
  }

  createDocument(agentId, kbId, data) {
    return axios.post(
      `${this.url}/${agentId}/knowledge_bases/${kbId}/knowledge_documents`,
      { knowledge_document: data }
    );
  }

  deleteDocument(agentId, kbId, docId) {
    return axios.delete(
      `${this.url}/${agentId}/knowledge_bases/${kbId}/knowledge_documents/${docId}`
    );
  }

  getTools(agentId) {
    return axios.get(`${this.url}/${agentId}/agent_tools`);
  }

  createTool(agentId, data) {
    return axios.post(`${this.url}/${agentId}/agent_tools`, {
      agent_tool: data,
    });
  }

  updateTool(agentId, toolId, data) {
    return axios.patch(`${this.url}/${agentId}/agent_tools/${toolId}`, {
      agent_tool: data,
    });
  }

  deleteTool(agentId, toolId) {
    return axios.delete(`${this.url}/${agentId}/agent_tools/${toolId}`);
  }

  createInboxLink(agentId, data) {
    return axios.post(`${this.url}/${agentId}/ai_agent_inboxes`, {
      ai_agent_inbox: data,
    });
  }

  updateInboxLink(agentId, linkId, data) {
    return axios.patch(`${this.url}/${agentId}/ai_agent_inboxes/${linkId}`, {
      ai_agent_inbox: data,
    });
  }

  deleteInboxLink(agentId, linkId) {
    return axios.delete(`${this.url}/${agentId}/ai_agent_inboxes/${linkId}`);
  }

  saveWorkflow(agentId, workflow) {
    return axios.patch(`${this.url}/${agentId}`, {
      ai_agent: { workflow },
    });
  }

  getWorkflowRuns(agentId, params = {}) {
    return axios.get(`${this.url}/${agentId}/workflow_runs`, { params });
  }

  getWorkflowRun(agentId, runId) {
    return axios.get(`${this.url}/${agentId}/workflow_runs/${runId}`);
  }

  /**
   * Send a preview/test message to the agent without creating a real conversation.
   * When stream=true, returns { request_id, stream: true } — subscribe to LlmChannel.
   */
  preview(agentId, { message, messages = [], stream = true }) {
    return axios.post(`${this.url}/${agentId}/preview`, {
      message,
      messages,
      stream,
    });
  }

  /**
   * Fetch available voices and models for the given provider.
   * Returns { voices: [...], models: [...] }
   */
  getVoiceCatalog(agentId, provider) {
    return axios.get(`${this.url}/${agentId}/voice_catalog`, {
      params: { provider },
    });
  }

  /**
   * Synthesize a short text preview for the given voice.
   * Returns { audio: 'base64...', content_type: 'audio/mpeg' }
   */
  previewVoice(agentId, { voiceId, text, modelId, provider, language }) {
    return axios.post(`${this.url}/${agentId}/voice_preview`, {
      voice_id: voiceId,
      text,
      model_id: modelId,
      provider,
      language,
    });
  }
}

export default new AiAgentsAPI();
