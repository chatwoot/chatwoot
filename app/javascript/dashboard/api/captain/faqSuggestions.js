/* global axios */
import ApiClient from '../ApiClient';

class CaptainFaqSuggestions extends ApiClient {
  constructor() {
    super('captain/faq_suggestions', { accountScoped: true });
  }

  show(id, { signal } = {}) {
    return axios.get(`${this.url}/${id}`, { signal });
  }

  get({ page = 1, search, assistantId, status = 'open', signal } = {}) {
    return axios.get(this.url, {
      params: {
        page,
        search,
        assistant_id: assistantId,
        status,
      },
      signal,
    });
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}`, { faq_suggestion: data });
  }

  approve(id, data) {
    return axios.post(`${this.url}/${id}/approve`, {
      faq_suggestion: data,
    });
  }

  dismiss(id) {
    return axios.post(`${this.url}/${id}/dismiss`);
  }
}

export default new CaptainFaqSuggestions();
