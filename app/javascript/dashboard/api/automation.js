import ApiClient from './ApiClient';

class AutomationsAPI extends ApiClient {
  constructor() {
    super('automation_rules', { accountScoped: true });
  }

  clone(automationId) {
    return this.axios.post(`${this.url}/${automationId}/clone`);
  }

  attachment(file) {
    return this.axios.post(`${this.url}/attach_file`, file, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }
}

export default new AutomationsAPI();
