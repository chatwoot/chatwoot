/* global axios */
import ApiClient from './ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }

  updateLabels(conversationID, labels) {
    return axios.post(`${this.url}/${conversationID}/labels`, { labels });
  }

  getUnreadCounts() {
    return axios.get(`${this.url}/unread_counts`);
  }

  // Kiraid: one-shot email composer (send email from dashboard).
  sendEmail({
    inbox_id,
    contact_id,
    subject,
    message,
    cc_emails = [],
    bcc_emails = [],
  }) {
    return axios.post(`${this.url}/send_email`, {
      inbox_id,
      contact_id,
      subject,
      message,
      cc_emails,
      bcc_emails,
    });
  }
}

export default new ConversationApi();
