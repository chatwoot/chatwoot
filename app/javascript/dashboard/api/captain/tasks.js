/* global axios */
import ApiClient from '../ApiClient';

/**
 * A client for the Captain Tasks API.
 * @extends ApiClient
 */
class TasksAPI extends ApiClient {
  /**
   * Creates a new TasksAPI instance.
   */
  constructor() {
    super('captain/tasks', { accountScoped: true });
  }

  /**
   * Rewrites content with a specific operation.
   * @param {Object} options - The rewrite options.
   * @param {string} options.content - The content to rewrite.
   * @param {string} options.operation - The rewrite operation (fix_spelling_grammar, casual, professional, etc).
   * @param {string} [options.conversationId] - The conversation ID for context (required for 'improve').
   * @param {AbortSignal} [signal] - AbortSignal to cancel the request.
   * @returns {Promise} A promise that resolves with the rewritten content.
   */
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

  /**
   * Summarizes a conversation.
   * @param {string} conversationId - The conversation ID to summarize.
   * @param {AbortSignal} [signal] - AbortSignal to cancel the request.
   * @returns {Promise} A promise that resolves with the summary.
   */
  summarize(conversationId, signal) {
    return axios.post(
      `${this.url}/summarize`,
      {
        conversation_display_id: conversationId,
      },
      { signal }
    );
  }

  /**
   * Gets a reply suggestion for a conversation.
   * @param {string} conversationId - The conversation ID.
   * @param {AbortSignal} [signal] - AbortSignal to cancel the request.
   * @returns {Promise} A promise that resolves with the reply suggestion.
   */
  replySuggestion(conversationId, signal) {
    return axios.post(
      `${this.url}/reply_suggestion`,
      {
        conversation_display_id: conversationId,
      },
      { signal }
    );
  }

  /**
   * Gets label suggestions for a conversation.
   * @param {string} conversationId - The conversation ID.
   * @param {AbortSignal} [signal] - AbortSignal to cancel the request.
   * @returns {Promise} A promise that resolves with label suggestions.
   */
  labelSuggestion(conversationId, signal) {
    return axios.post(
      `${this.url}/label_suggestion`,
      {
        conversation_display_id: conversationId,
      },
      { signal }
    );
  }

  /**
   * Sends a follow-up message to continue refining a previous task result.
   * @param {Object} options - The follow-up options.
   * @param {Object} options.followUpContext - The follow-up context from a previous task.
   * @param {string} options.message - The follow-up message/request from the user.
   * @param {string} [options.conversationId] - The conversation ID for Langfuse session tracking.
   * @param {AbortSignal} [signal] - AbortSignal to cancel the request.
   * @returns {Promise} A promise that resolves with the follow-up response and updated follow-up context.
   */
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
