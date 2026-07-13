import ApiClient from './ApiClient';

class TaskTemplatesAPI extends ApiClient {
  constructor() {
    super('task_templates', { accountScoped: true });
  }
}

export default new TaskTemplatesAPI();
