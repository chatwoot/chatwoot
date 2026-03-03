/* global axios */
import ApiClient from '../ApiClient';

class TasksAPI extends ApiClient {
  constructor() {
    super('nauto_assistant/tasks', { accountScoped: true });
  }

  rewrite({ content, operation, conversationId }, signal) {
    return axios.post(
      `${this.url}/rewrite`,
      {
        content,
        operation,
        conversation_display_id: conversationId,
      },
      { signal }
    );
  }

  summarize(conversationId, signal) {
    return axios.post(
      `${this.url}/summarize`,
      {
        conversation_display_id: conversationId,
      },
      { signal }
    );
  }

  replySuggestion(conversationId, signal) {
    return axios.post(
      `${this.url}/reply_suggestion`,
      {
        conversation_display_id: conversationId,
      },
      { signal }
    );
  }

  labelSuggestion(conversationId, signal) {
    return axios.post(
      `${this.url}/label_suggestion`,
      {
        conversation_display_id: conversationId,
      },
      { signal }
    );
  }

  followUp({ followUpContext, message, conversationId }, signal) {
    return axios.post(
      `${this.url}/follow_up`,
      {
        follow_up_context: followUpContext,
        message,
        conversation_display_id: conversationId,
      },
      { signal }
    );
  }
}

export default new TasksAPI();
