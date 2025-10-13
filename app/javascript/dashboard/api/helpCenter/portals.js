/* global axios */
import ApiClient from '../ApiClient';

class PortalsAPI extends ApiClient {
  constructor() {
    super('portals', { accountScoped: true });
  }

  getPortal({ portalSlug, locale }) {
    return axios.get(`${this.url}/${portalSlug}?locale=${locale}`);
  }

  updatePortal({ portalSlug, portalObj }) {
    return axios.patch(`${this.url}/${portalSlug}`, portalObj);
  }

  deletePortal(portalSlug) {
    return axios.delete(`${this.url}/${portalSlug}`);
  }

  deleteLogo(portalSlug) {
    return axios.delete(`${this.url}/${portalSlug}/logo`);
  }

  sendCnameInstructions(portalSlug, email) {
    return axios.post(`${this.url}/${portalSlug}/send_instructions`, { email });
  }

  sslStatus(portalSlug) {
    return axios.get(`${this.url}/${portalSlug}/ssl_status`);
  }
}

export default PortalsAPI;
