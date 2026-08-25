import ApiClient from './ApiClient';

// Phone numbers provisioned in the Pathors admin console for the connected
// account. Returns 404 `integration_not_connected` when the account has no
// Pathors integration.
class PathorsPhoneNumbersAPI extends ApiClient {
  constructor() {
    super('pathors/phone_numbers', { accountScoped: true });
  }
}

export default new PathorsPhoneNumbersAPI();
