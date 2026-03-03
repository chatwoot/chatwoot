/* global axios */
import ApiClient from './ApiClient';

class InfluencerProfilesAPI extends ApiClient {
  constructor() {
    super('influencer_profiles', { accountScoped: true });
  }

  get(page = 1, filters = {}) {
    const params = new URLSearchParams({ page });
    if (filters.status) params.append('status', filters.status);
    if (filters.minFqs) params.append('min_fqs', filters.minFqs);
    if (filters.maxFqs) params.append('max_fqs', filters.maxFqs);
    if (filters.targetMarket)
      params.append('target_market', filters.targetMarket);
    return axios.get(`${this.url}?${params}`);
  }

  show(id) {
    return axios.get(`${this.url}/${id}`);
  }

  search(filters = {}, page = 1) {
    return axios.post(`${this.url}/search`, { ...filters, page });
  }

  importProfile(searchResult, targetMarket) {
    return axios.post(`${this.url}/import`, {
      search_result: searchResult,
      target_market: targetMarket,
    });
  }

  bulkImport(searchResults, targetMarket) {
    return axios.post(`${this.url}/bulk_import`, {
      search_results: searchResults,
      target_market: targetMarket,
    });
  }

  requestReport(id) {
    return axios.post(`${this.url}/${id}/request_report`);
  }

  bulkRequestReport(profileIds) {
    return axios.post(`${this.url}/bulk_request_report`, {
      profile_ids: profileIds,
    });
  }

  approve(id) {
    return axios.post(`${this.url}/${id}/approve`);
  }

  reject(id, reason = '') {
    return axios.post(`${this.url}/${id}/reject`, { reason });
  }

  recalculate(id) {
    return axios.post(`${this.url}/${id}/recalculate`);
  }

  retryApify(id) {
    return axios.post(`${this.url}/${id}/retry_apify`);
  }

  getConversations(profileId) {
    return axios.get(`${this.url}/${profileId}/conversations`);
  }

  sendMessage(profileId, { inboxId, content }) {
    return axios.post(`${this.url}/${profileId}/send_message`, {
      inbox_id: inboxId,
      content,
    });
  }

  createOffer(profileId, { packages, rightsLevel, currency }) {
    return axios.post(`${this.url}/${profileId}/create_offer`, {
      packages,
      rights_level: rightsLevel,
      currency,
    });
  }

  getOffers(profileId) {
    return axios.get(`${this.url}/${profileId}/offers`);
  }

  updateEmail(profileId, email) {
    return axios.patch(`${this.url}/${profileId}/update_email`, { email });
  }

  addByHandle(handle) {
    return axios.post(`${this.url}/add_by_handle`, { handle });
  }

  delete(id) {
    return axios.delete(`${this.url}/${id}`);
  }

  proxyImageUrl(externalUrl) {
    return `${this.url}/proxy_image?url=${encodeURIComponent(externalUrl)}`;
  }
}

export default new InfluencerProfilesAPI();
