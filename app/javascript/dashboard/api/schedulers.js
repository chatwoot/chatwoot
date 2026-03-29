import ApiClient from './ApiClient';

class SchedulersAPI extends ApiClient {
  constructor() {
    super('schedulers', { accountScoped: true });
  }
}

export default new SchedulersAPI();
