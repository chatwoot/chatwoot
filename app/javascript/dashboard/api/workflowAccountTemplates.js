/* global axios */

import ApiClient from './ApiClient';

class WorkflowAccountTemplatesApi extends ApiClient {
  constructor() {
    super('workflow/account_templates', { accountScoped: true });
  }
}

export default new WorkflowAccountTemplatesApi();
