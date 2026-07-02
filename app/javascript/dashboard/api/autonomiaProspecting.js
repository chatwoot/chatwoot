/* global axios */
import ApiClient from './ApiClient';

class AutonomiaProspectingAPI extends ApiClient {
  constructor() {
    super('autonomia/prospecting', { accountScoped: true });
  }

  getSearches() {
    return axios.get(`${this.url}/searches`);
  }

  getLeads() {
    return axios.get(`${this.url}/leads`);
  }

  getLists() {
    return axios.get(`${this.url}/lists`);
  }

  getSettings() {
    return axios.get(`${this.url}/settings`);
  }
}

export default new AutonomiaProspectingAPI();
