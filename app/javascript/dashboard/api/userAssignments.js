/* global axios */
import ApiClient from './ApiClient';

class UserAssignmentsAPI extends ApiClient {
  constructor() {
    super('user_assignments', { accountScoped: true });
  }

  getAvailableTemplates() {
    return axios.get(`${this.url}/available_templates`);
  }
}

export default new UserAssignmentsAPI();
