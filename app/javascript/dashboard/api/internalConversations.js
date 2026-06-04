/* global axios */
import ApiClient from './ApiClient';

class InternalConversationsAPI extends ApiClient {
  constructor() {
    super('internal_conversations', { accountScoped: true });
  }

  create(payload) {
    // eslint-disable-next-line no-console
    console.log('[InternalConversationsAPI] create', { payload });
    return axios.post(this.url, payload);
  }

  initiateVoiceCall({ conversationId, voiceInboxId, targetAgentId }) {
    // eslint-disable-next-line no-console
    console.log('[InternalConversationsAPI] initiateVoiceCall', {
      conversationId,
      voiceInboxId,
      targetAgentId,
    });
    return axios.post(`${this.url}/${conversationId}/voice_call`, {
      voice_inbox_id: voiceInboxId,
      target_agent_id: targetAgentId,
    });
  }
}

export default new InternalConversationsAPI();

