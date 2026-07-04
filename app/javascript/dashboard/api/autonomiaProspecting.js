/* global axios */
import ApiClient from './ApiClient';

class AutonomiaProspectingAPI extends ApiClient {
  constructor() {
    super('autonomia/prospecting', { accountScoped: true });
  }

  getSearches() {
    return axios.get(`${this.url}/searches`);
  }

  getSearch(searchId) {
    return axios.get(`${this.url}/searches/${searchId}`);
  }

  createSearch(search) {
    return axios.post(`${this.url}/searches`, { search });
  }

  getLeads(params = {}) {
    return axios.get(`${this.url}/leads`, { params });
  }

  createLeadContact(leadId) {
    return axios.post(`${this.url}/leads/${leadId}/contact`);
  }

  getLists() {
    return axios.get(`${this.url}/lists`);
  }

  getList(listId) {
    return axios.get(`${this.url}/lists/${listId}`);
  }

  createList(list) {
    return axios.post(`${this.url}/lists`, { list });
  }

  addLeadToList(listId, leadId) {
    return axios.post(`${this.url}/lists/${listId}/leads`, { lead_id: leadId });
  }

  removeLeadFromList(listId, leadId) {
    return axios.delete(`${this.url}/lists/${listId}/leads/${leadId}`);
  }

  getSettings() {
    return axios.get(`${this.url}/settings`);
  }

  updateSettings(settings) {
    return axios.patch(`${this.url}/settings`, { settings });
  }
}

export default new AutonomiaProspectingAPI();
