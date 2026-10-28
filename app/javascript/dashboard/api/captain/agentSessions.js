import ApiClient from '../ApiClient';

class CaptainAgentSessions extends ApiClient {
  constructor() {
    super('captain/agent_sessions', { accountScoped: true });
  }
}

export default new CaptainAgentSessions();
