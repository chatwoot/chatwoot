import ApiClient from './ApiClient';

// Pathors agent bots available to the account, each with the id of the project
// that answers for it. Used by the voice wizard to pick who takes the call.
class PathorsAgentBotsAPI extends ApiClient {
  constructor() {
    super('pathors/agent_bots', { accountScoped: true });
  }
}

export default new PathorsAgentBotsAPI();
