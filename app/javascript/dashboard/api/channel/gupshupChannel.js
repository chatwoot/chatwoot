import ApiClient from '../ApiClient';

class GupshupChannel extends ApiClient {
  constructor() {
    super('channels/gupshup_channel', { accountScoped: true });
  }
}

export default new GupshupChannel();
