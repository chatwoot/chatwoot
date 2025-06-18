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

  checkDomain({ domain, initialCustomDomain }) {
    return axios.get(
      `${this.url}/check?domain=${domain}&initialCustomDomain=${initialCustomDomain}`
    );
  }

  removeDomain({  initialCustomDomain }) {
    return axios.delete(
      `${this.url}/remove_domain?initialCustomDomain=${initialCustomDomain}`
    );
  }
}

export default PortalsAPI;
