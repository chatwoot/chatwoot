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

    /**
     * The conversation events supported by the API.
     * @type {string[]}
     */
    this.conversation_events = ['summarize', 'reply_suggestion'];

    /**
     * The message events supported by the API.
     * @type {string[]}
     */
    this.message_events = ['rephrase'];
  }

  /**
   * Processes an event using the Captain Editor API.
   * @param {Object} options - The options for the event.
   * @param {string} [options.type='rephrase'] - The type of event to process.
   * @param {string} [options.content] - The content of the event.
   * @param {string} [options.tone] - The tone of the event.
   * @param {string} [options.conversationId] - The ID of the conversation to process the event for.
   * @param {AbortSignal} [signal] - AbortSignal to cancel the request.
   * @returns {Promise} A promise that resolves with the result of the event processing.
   */
  processEvent({ type = 'rephrase', content, tone, conversationId }, signal) {
    /**
     * @type {Object}
     */
    let data = {
      tone,
      content,
    };

    // Always include conversation_display_id when available for session tracking
    if (conversationId) {
      data.conversation_display_id = conversationId;
    }

    // For conversation-level events, only send conversation_display_id
    if (this.conversation_events.includes(type)) {
      data = {
        conversation_display_id: conversationId,
      };
    }

    return axios.post(
      `${this.url}/process_event`,
      {
        event: {
          name: type,
          data,
        },
      },
      { signal }
    );
  }
}

export default new EditorAPI();
