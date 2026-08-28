/* global axios */
import ApiClient from '../ApiClient';

class CopilotPendingAdminActions extends ApiClient {
  constructor() {
    super('captain/copilot_threads', { accountScoped: true });
  }

  get(threadId) {
    return axios.get(`${this.url}/${threadId}/copilot_pending_admin_actions`);
  }

  confirm(threadId, id) {
    return axios.post(
      `${this.url}/${threadId}/copilot_pending_admin_actions/${id}/confirm`
    );
  }

  reject(threadId, id) {
    return axios.post(
      `${this.url}/${threadId}/copilot_pending_admin_actions/${id}/reject`
    );
  }
}

export default new CopilotPendingAdminActions();
