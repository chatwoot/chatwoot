import ApiClient from './ApiClient';

class Agents extends ApiClient {
  constructor() {
    super('agents');
  }
}

export default new Agents();
