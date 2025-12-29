/* global axios */
import ApiClient from './ApiClient';

class LeadFollowUpSequencesAPI extends ApiClient {
  constructor() {
    super('copilot_sequences', { accountScoped: true });
  }

  activate(sequenceId) {
    return axios.post(`${this.url}/${sequenceId}/activate`);
  }

  deactivate(sequenceId) {
    return axios.post(`${this.url}/${sequenceId}/deactivate`);
  }

  getAvailableTemplates(inboxId) {
    return axios.get(`${this.url}/available_templates`, {
      params: { inbox_id: inboxId },
    });
  }

  previewEligible(params) {
    return axios.post(`${this.url}/preview_eligible`, params);
  }

  getEnrolledConversations(sequenceId, params = {}) {
    return axios.get(`${this.url}/${sequenceId}/enrolled_conversations`, {
      params: params,
    });
  }

  cancelFollowUps(sequenceId, followUpIds) {
    return axios.post(`${this.url}/${sequenceId}/cancel_follow_ups`, {
      follow_up_ids: followUpIds,
    });
  }
}

export default new LeadFollowUpSequencesAPI();
