import ApiClient from './ApiClient';

class PaymentLinksAPI extends ApiClient {
  constructor() {
    super('payment_links', { accountScoped: true });
  }
}

export default new PaymentLinksAPI();
