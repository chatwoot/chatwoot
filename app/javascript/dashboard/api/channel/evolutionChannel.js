import ApiClient from '../ApiClient';

class EvolutionChannel extends ApiClient {
  constructor() {
    super('channels/evolution_channel', { accountScoped: true });
  }
}

export default new EvolutionChannel();
