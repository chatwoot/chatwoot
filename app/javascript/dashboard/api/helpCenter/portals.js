/* global axios */
import ApiClient from '../ApiClient';

class PortalsAPI extends ApiClient {
  constructor() {
    super('portals', { accountScoped: true });
  }

  updatePortal({ portalSlug, params }) {
    return axios.patch(`${this.url}/${portalSlug}`, params);
  }

  deletePortal(portalSlug) {
    return axios.delete(`${this.url}/${portalSlug}`);
  }
}

export default PortalsAPI;
