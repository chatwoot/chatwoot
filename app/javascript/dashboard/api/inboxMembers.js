/* global axios */
import ApiClient from './ApiClient';

class InboxMembers extends ApiClient {
  constructor() {
    super('inbox_members', { accountScoped: true });
  }

  update({ inboxId, agentList }) {
    return axios.patch(this.url, {
      inbox_id: inboxId,
      user_ids: agentList,
    });
  }

  updateAssignmentEligibility({ inboxId, userId, assignmentEligible }) {
    return axios.patch(`${this.url}/${inboxId}/update_assignment_eligibility`, {
      user_id: userId,
      assignment_eligible: assignmentEligible,
    });
  }
}

export default new InboxMembers();
