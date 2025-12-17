/* global axios */
import ApiClient from '../ApiClient';

/**
 * A client for the Captain Editor API.
 * @extends ApiClient
 */
class EditorAPI extends ApiClient {
  /**
   * Creates a new EditorAPI instance.
   */
  constructor() {
    super('captain/editor', { accountScoped: true });
  }

  /**
   * Processes an event using the Captain Editor API.
   * @param {Object} options - The options for the event.
   * @param {string} [options.type='improve'] - The type of event to process.
   * @param {string} [options.content] - The content of the event.
   * @param {string} [options.conversationId] - The ID of the conversation to process the event for.
   * @param {AbortSignal} [signal] - AbortSignal to cancel the request.
   * @returns {Promise} A promise that resolves with the result of the event processing.
   */
  processEvent({ type = 'improve', content, conversationId }, signal) {
    // Route to appropriate endpoint based on type
    if (type === 'summarize') {
      return this.summarize(conversationId, signal);
    }

    if (type === 'reply_suggestion') {
      return this.replySuggestion(conversationId, signal);
    }

    if (type === 'label_suggestion') {
      return this.labelSuggestion(conversationId, signal);
    }

    // All other types are rewrite actions
    return this.rewrite({ content, action: type, conversationId }, signal);
  }

  /**
   * Rewrites content with a specific action.
   * @param {Object} options - The rewrite options.
   * @param {string} options.content - The content to rewrite.
   * @param {string} options.action - The rewrite action (fix_spelling_grammar, casual, professional, etc).
   * @param {string} [options.conversationId] - The conversation ID for context (required for 'improve').
   * @param {AbortSignal} [signal] - AbortSignal to cancel the request.
   * @returns {Promise} A promise that resolves with the rewritten content.
   */
  rewrite({ content, action, conversationId }, signal) {
    return axios.post(
      `${this.url}/rewrite`,
      {
        content,
        action,
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
}

export default new EditorAPI();
