import ApiClient from './ApiClient';

class LabelsAPI extends ApiClient {
  constructor() {
    super('labels', { accountScoped: true });
  }
}

export default new LabelsAPI();
