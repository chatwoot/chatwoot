/* global axios */
import ApiClient from './ApiClient';

class AIFeaturesAPI extends ApiClient {
  constructor() {
    super('ai', { accountScoped: true });
  }

  // Semantic Search
  searchConversationsSemantic(params) {
    return axios.post(`${this.url}/semantic_search`, params);
  }

  // Canned Response Suggestions
  fetchCannedResponseSuggestions(conversationId, params = {}) {
    return axios.get(`${this.url}/canned_response_suggestions/${conversationId}`, {
      params,
    });
  }

  submitCannedResponseFeedback(data) {
    return axios.post(`${this.url}/canned_response_feedback`, data);
  }

  // Contact Memories
  fetchContactMemories(contactId) {
    return axios.get(`${this.url}/contact_memories/${contactId}`);
  }

  createContactMemory(contactId, data) {
    return axios.post(`${this.url}/contact_memories/${contactId}`, data);
  }

  searchContactMemories(contactId, query) {
    return axios.get(`${this.url}/contact_memories/${contactId}/search`, {
      params: { query },
    });
  }

  updateContactMemory(contactId, memoryId, data) {
    return axios.patch(`${this.url}/contact_memories/${contactId}/${memoryId}`, data);
  }

  deleteContactMemory(contactId, memoryId) {
    return axios.delete(`${this.url}/contact_memories/${contactId}/${memoryId}`);
  }

  // Similar Tickets
  fetchSimilarConversations(conversationId, params = {}) {
    return axios.get(`${this.url}/similar_conversations/${conversationId}`, {
      params,
    });
  }

  // RLHF Feedback
  submitRLHFFeedback(data) {
    return axios.post(`${this.url}/rlhf_feedback`, data);
  }
}

export default new AIFeaturesAPI();
