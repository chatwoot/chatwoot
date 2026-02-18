/* global axios */
import ApiClient from './ApiClient';

class CrmFlowsAPI extends ApiClient {
  constructor() {
    super('crm_flows', { accountScoped: true });
  }

  trigger(data, idempotencyKey) {
    return axios.post(`${this.url}/trigger`, data, {
      headers: { 'Idempotency-Key': idempotencyKey },
    });
  }

  triggerSchema(triggerType, inboxId) {
    const params = { trigger_type: triggerType };
    if (inboxId) params.inbox_id = inboxId;
    return axios.get(`${this.url}/trigger_schema`, { params });
  }

  executions(flowId) {
    return axios.get(`${this.url}/${flowId}/executions`);
  }

  executionsByConversation(conversationId) {
    return axios.get(`${this.url}/executions_by_conversation`, {
      params: { conversation_id: conversationId },
    });
  }
}

export default new CrmFlowsAPI();
