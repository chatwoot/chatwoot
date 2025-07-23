/* global axios */
import ApiClient from './ApiClient';

class AiMessageFeedbacksAPI extends ApiClient {
  constructor() {
    super('ai_message_feedbacks', { accountScoped: true });
  }

  create(messageId, feedbackData) {
    return axios.post(this.url, {
      message_id: messageId,
      ai_feedback: feedbackData,
    });
  }

  update(messageId, feedbackData) {
    return axios.patch(this.url, {
      message_id: messageId,
      ai_feedback: feedbackData,
    });
  }

  delete(messageId) {
    return axios.delete(`${this.url}/${messageId}`);
  }
}

export default new AiMessageFeedbacksAPI(); 