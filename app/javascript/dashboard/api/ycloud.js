/* global axios */

// YCloud API client for all YCloud-specific WhatsApp channel operations.
// Base URL: /api/v1/accounts/:account_id/channels/whatsapp/ycloud/:inbox_id/

class YCloudAPI {
  constructor() {
    this.resource = 'channels/whatsapp/ycloud';
  }

  // eslint-disable-next-line class-methods-use-this
  get accountIdFromRoute() {
    const isInsideAccountScopedURLs =
      window.location.pathname.includes('/app/accounts');
    if (isInsideAccountScopedURLs) {
      return window.location.pathname.split('/')[3];
    }
    return '';
  }

  baseUrl(inboxId) {
    return `/api/v1/accounts/${this.accountIdFromRoute}/${this.resource}/${inboxId}`;
  }

  // --- Templates ---
  listTemplates(inboxId, { page = 1, limit = 100 } = {}) {
    return axios.get(`${this.baseUrl(inboxId)}/templates`, {
      params: { page, limit },
    });
  }

  showTemplate(inboxId, name, language) {
    return axios.get(`${this.baseUrl(inboxId)}/templates/${name}/${language}`);
  }

  createTemplate(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/templates`, data);
  }

  updateTemplate(inboxId, name, language, data) {
    return axios.patch(
      `${this.baseUrl(inboxId)}/templates/${name}/${language}`,
      data
    );
  }

  deleteTemplate(inboxId, name, language = null) {
    const url = language
      ? `${this.baseUrl(inboxId)}/templates/${name}/${language}`
      : `${this.baseUrl(inboxId)}/templates/${name}`;
    return axios.delete(url);
  }

  // --- Flows ---
  listFlows(inboxId, { page = 1, limit = 20 } = {}) {
    return axios.get(`${this.baseUrl(inboxId)}/flows`, {
      params: { page, limit },
    });
  }

  showFlow(inboxId, flowId) {
    return axios.get(`${this.baseUrl(inboxId)}/flows/${flowId}`);
  }

  createFlow(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/flows`, data);
  }

  updateFlowMetadata(inboxId, flowId, data) {
    return axios.patch(
      `${this.baseUrl(inboxId)}/flows/${flowId}/metadata`,
      data
    );
  }

  updateFlowStructure(inboxId, flowId, data) {
    return axios.patch(
      `${this.baseUrl(inboxId)}/flows/${flowId}/structure`,
      data
    );
  }

  deleteFlow(inboxId, flowId) {
    return axios.delete(`${this.baseUrl(inboxId)}/flows/${flowId}`);
  }

  publishFlow(inboxId, flowId) {
    return axios.post(`${this.baseUrl(inboxId)}/flows/${flowId}/publish`);
  }

  deprecateFlow(inboxId, flowId) {
    return axios.post(`${this.baseUrl(inboxId)}/flows/${flowId}/deprecate`);
  }

  previewFlow(inboxId, flowId) {
    return axios.get(`${this.baseUrl(inboxId)}/flows/${flowId}/preview`);
  }

  // --- Business Profile ---
  getProfile(inboxId) {
    return axios.get(`${this.baseUrl(inboxId)}/profile`);
  }

  updateProfile(inboxId, data) {
    return axios.patch(`${this.baseUrl(inboxId)}/profile`, data);
  }

  listPhoneNumbers(inboxId) {
    return axios.get(`${this.baseUrl(inboxId)}/phone_numbers`);
  }

  getCommerceSettings(inboxId) {
    return axios.get(`${this.baseUrl(inboxId)}/commerce_settings`);
  }

  updateCommerceSettings(inboxId, data) {
    return axios.patch(`${this.baseUrl(inboxId)}/commerce_settings`, data);
  }

  // --- Calling ---
  connectCall(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/calls/connect`, data);
  }

  preAcceptCall(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/calls/pre_accept`, data);
  }

  acceptCall(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/calls/accept`, data);
  }

  terminateCall(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/calls/terminate`, data);
  }

  rejectCall(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/calls/reject`, data);
  }

  // --- Messaging actions ---
  markAsRead(inboxId, messageId) {
    return axios.post(`${this.baseUrl(inboxId)}/mark_as_read`, {
      message_id: messageId,
    });
  }

  sendTypingIndicator(inboxId, phoneNumber) {
    return axios.post(`${this.baseUrl(inboxId)}/typing_indicator`, {
      phone_number: phoneNumber,
    });
  }

  uploadMedia(inboxId, formData) {
    return axios.post(`${this.baseUrl(inboxId)}/upload_media`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  }

  // --- YCloud CRM Contacts ---
  listYCloudContacts(inboxId, { page = 1, limit = 20 } = {}) {
    return axios.get(`${this.baseUrl(inboxId)}/ycloud_contacts`, {
      params: { page, limit },
    });
  }

  showYCloudContact(inboxId, contactId) {
    return axios.get(`${this.baseUrl(inboxId)}/ycloud_contacts/${contactId}`);
  }

  createYCloudContact(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/ycloud_contacts`, data);
  }

  updateYCloudContact(inboxId, contactId, data) {
    return axios.patch(
      `${this.baseUrl(inboxId)}/ycloud_contacts/${contactId}`,
      data
    );
  }

  deleteYCloudContact(inboxId, contactId) {
    return axios.delete(
      `${this.baseUrl(inboxId)}/ycloud_contacts/${contactId}`
    );
  }

  // --- Custom Events ---
  createEventDefinition(inboxId, data) {
    return axios.post(
      `${this.baseUrl(inboxId)}/custom_events/definitions`,
      data
    );
  }

  sendCustomEvent(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/custom_events`, data);
  }

  // --- Multi-channel ---
  sendSms(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/sms`, data);
  }

  sendEmail(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/email`, data);
  }

  sendVoice(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/voice`, data);
  }

  startVerification(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/verification/start`, data);
  }

  checkVerification(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/verification/check`, data);
  }

  // --- Unsubscribers ---
  listUnsubscribers(inboxId, { page = 1, limit = 20 } = {}) {
    return axios.get(`${this.baseUrl(inboxId)}/unsubscribers`, {
      params: { page, limit },
    });
  }

  createUnsubscriber(inboxId, data) {
    return axios.post(`${this.baseUrl(inboxId)}/unsubscribers`, data);
  }

  checkUnsubscriber(inboxId, customer, channel) {
    return axios.get(
      `${this.baseUrl(inboxId)}/unsubscribers/${customer}/${channel}`
    );
  }

  deleteUnsubscriber(inboxId, customer, channel) {
    return axios.delete(
      `${this.baseUrl(inboxId)}/unsubscribers/${customer}/${channel}`
    );
  }

  // --- Webhook Endpoints ---
  listWebhookEndpoints(inboxId) {
    return axios.get(`${this.baseUrl(inboxId)}/webhook_endpoints`);
  }

  rotateWebhookSecret(inboxId, endpointId) {
    return axios.post(
      `${this.baseUrl(inboxId)}/webhook_endpoints/${endpointId}/rotate_secret`
    );
  }

  // --- Account ---
  getBalance(inboxId) {
    return axios.get(`${this.baseUrl(inboxId)}/balance`);
  }

  listBusinessAccounts(inboxId) {
    return axios.get(`${this.baseUrl(inboxId)}/business_accounts`);
  }
}

export default new YCloudAPI();
