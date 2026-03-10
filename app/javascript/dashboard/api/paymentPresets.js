import ApiClient from './ApiClient';

class PaymentPresetsAPI extends ApiClient {
  constructor() {
    super('payment_presets', { accountScoped: true });
  }
}

export default new PaymentPresetsAPI();
