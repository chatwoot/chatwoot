/* global axios */
import ApiClient from './ApiClient';

class InboxFaqCategoriesAPI extends ApiClient {
  constructor() {
    super('faq_categories', { accountScoped: true });
  }

  getCategories(inboxId) {
    return axios.get(this.getInboxUrl(inboxId));
  }

  syncCategories(inboxId, categoryIds) {
    return axios.post(this.getInboxUrl(inboxId), {
      faq_category_ids: categoryIds,
    });
  }

  getInboxUrl(inboxId) {
    return `${this.baseUrl()}/inboxes/${inboxId}/faq_categories`;
  }
}

export default new InboxFaqCategoriesAPI();
