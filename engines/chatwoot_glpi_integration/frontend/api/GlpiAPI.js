/* global axios */
import ApiClient from 'dashboard/api/ApiClient';

class GlpiConnectionAPI extends ApiClient {
  constructor() { super('glpi/connection', { accountScoped: true }); }
  test() { return axios.post(`${this.url}/test`); }
}

class GlpiTicketsAPI extends ApiClient {
  constructor() { super('glpi/tickets', { accountScoped: true }); }
  sync(id)        { return axios.post(`${this.url}/${id}/sync`); }
  reconcileAll()  { return axios.post(`${this.url}/reconcile_all`); }
}

export const GlpiConnection = new GlpiConnectionAPI();
export const GlpiTickets    = new GlpiTicketsAPI();
