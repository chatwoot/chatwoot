/* global axios */

import ApiClient from './ApiClient';

class AssignmentPolicies extends ApiClient {
  constructor() {
    super('assignment_policies', { accountScoped: true });
  }

  getInboxes(policyId) {
    return axios.get(`${this.url}/${policyId}/inboxes`);
  }

  setInboxPolicy(inboxId, policyId) {
    return axios.post(
      `/api/v1/accounts/${this.accountIdFromRoute}/inboxes/${inboxId}/assignment_policy`,
      {
        assignment_policy_id: policyId,
      }
    );
  }

  getInboxPolicy(inboxId) {
    return axios.get(
      `/api/v1/accounts/${this.accountIdFromRoute}/inboxes/${inboxId}/assignment_policy`
    );
  }

  removeInboxPolicy(inboxId) {
    return axios.delete(
      `/api/v1/accounts/${this.accountIdFromRoute}/inboxes/${inboxId}/assignment_policy`
    );
  }
}

export default new AssignmentPolicies();
