import ApiClient from './ApiClient';

class Agents extends ApiClient {
  constructor() {
    super('agents', { accountScoped: true });
  }

  generate_token() {
    return axios.get(`${this.url}/secure_token`);
  }
}

export default new Agents();
