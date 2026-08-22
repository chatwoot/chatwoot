/* global axios */
import ApiClient from './ApiClient';

export const buildContactParams = (
  page,
  sortAttr,
  label,
  search,
  perPage
) => {
  const params = {
    include_contact_inboxes: false,
    page,
    sort: sortAttr || '',
    ...(search ? { q: search } : {}),
    ...(label ? { labels: [label] } : {}),
    ...(perPage ? { per_page: perPage } : {}),
  };

  // Encode sort so custom:key / -custom:key survive query parsing
  if (params.sort) {
    params.sort = encodeURIComponent(params.sort);
  }

  return params;
};

class ContactAPI extends ApiClient {
  constructor() {
    super('contacts', { accountScoped: true });
  }

  // eslint-disable-next-line default-param-last
  get(page, sortAttr = 'name', label = '', perPage) {
    return axios.get(this.url, {
      params: buildContactParams(page, sortAttr, label, '', perPage),
    });
  }

  show(id) {
    return axios.get(`${this.url}/${id}?include_contact_inboxes=false`);
  }

  update(id, data) {
    return axios.patch(`${this.url}/${id}?include_contact_inboxes=false`, data);
  }

  getConversations(contactId, { inboxId, sortBy } = {}) {
    const params = {};
    if (inboxId) params.inbox_id = inboxId;
    if (sortBy) params.sort_by = sortBy;
    return axios.get(`${this.url}/${contactId}/conversations`, { params });
  }

  getAttachments(contactId, page = 1) {
    return axios.get(`${this.url}/${contactId}/attachments`, {
      params: { page },
    });
  }

  getContactableInboxes(contactId) {
    return axios.get(`${this.url}/${contactId}/contactable_inboxes`);
  }

  getContactLabels(contactId) {
    return axios.get(`${this.url}/${contactId}/labels`);
  }

  initiateCall(contactId, inboxId, conversationId = null) {
    return axios.post(`${this.url}/${contactId}/call`, {
      inbox_id: inboxId,
      conversation_id: conversationId,
    });
  }

  updateContactLabels(contactId, labels) {
    return axios.post(`${this.url}/${contactId}/labels`, { labels });
  }

  search(search = '', page = 1, sortAttr = 'name', label = '', options = {}) {
    return axios.get(`${this.url}/search`, {
      params: buildContactParams(
        page,
        sortAttr,
        label,
        search,
        options.perPage
      ),
      signal: options.signal,
    });
  }

  // eslint-disable-next-line default-param-last
  active(page = 1, sortAttr = 'name', perPage) {
    return axios.get(`${this.url}/active`, {
      params: buildContactParams(page, sortAttr, '', '', perPage),
    });
  }

  // eslint-disable-next-line default-param-last
  filter(page = 1, sortAttr = 'name', queryPayload, perPage) {
    return axios.post(`${this.url}/filter`, queryPayload, {
      params: buildContactParams(page, sortAttr, '', '', perPage),
    });
  }

  importContacts(file) {
    const formData = new FormData();
    formData.append('import_file', file);
    return axios.post(`${this.url}/import`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  destroyCustomAttributes(contactId, customAttributes) {
    return axios.post(`${this.url}/${contactId}/destroy_custom_attributes`, {
      custom_attributes: customAttributes,
    });
  }

  destroyAvatar(contactId) {
    return axios.delete(`${this.url}/${contactId}/avatar`);
  }

  exportContacts(queryPayload) {
    return axios.post(`${this.url}/export`, queryPayload);
  }
}

export default new ContactAPI();
