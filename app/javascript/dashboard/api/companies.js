/* global axios */
import ApiClient from './ApiClient';

class CompaniesAPI extends ApiClient {
  constructor() {
    super('companies', { accountScoped: true });
  }
}

export default new CompaniesAPI();
