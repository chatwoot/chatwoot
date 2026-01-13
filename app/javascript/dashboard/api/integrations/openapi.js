/* global axios */

import ApiClient from '../ApiClient';

/**
 * Represents the data object for a OpenAI hook.
 * @typedef {Object} ConversationMessageData
 * @property {string} [tone] - The tone of the message.
 * @property {string} [content] - The content of the message.
 * @property {string} [conversation_display_id] - The display ID of the conversation (optional).
 */

/**
 * A client for the OpenAI API.
 * @extends ApiClient
 */
class OpenAIAPI extends ApiClient {
  /**
   * Creates a new OpenAIAPI instance.
   */
  constructor() {
    super('integrations', { accountScoped: true });

    /**
     * The conversation events supported by the API.
     * @type {string[]}
     */
    this.conversation_events = [
      'summarize',
      'reply_suggestion',
      'label_suggestion',
    ];

    /**
     * The message events supported by the API.
     * @type {string[]}
     */
    this.message_events = ['rephrase'];
  }

  /**
   * Processes an event using the OpenAI API.
   * @param {Object} options - The options for the event.
   * @param {string} [options.type='rephrase'] - The type of event to process.
   * @param {string} [options.content] - The content of the event.
   * @param {string} [options.tone] - The tone of the event.
   * @param {string} [options.conversationId] - The ID of the conversation to process the event for.
   * @param {string} options.hookId - The ID of the hook to use for processing the event (not needed if useGlobalEndpoint is true).
   * @param {boolean} options.useGlobalEndpoint - Whether to use the global AI endpoint (for global key feature).
   * @returns {Promise} A promise that resolves with the result of the event processing.
   */
  processEvent({
    type = 'rephrase',
    content,
    tone,
    conversationId,
    hookId,
    useGlobalEndpoint = false,
  }) {
    /**
     * @type {ConversationMessageData}
     */
    let data = {
      tone,
      content,
    };

    if (this.conversation_events.includes(type)) {
      data = {
        conversation_display_id: conversationId,
      };
    }

    const eventPayload = {
      event: {
        name: type,
        data,
      },
    };

    // Use global endpoint if global key feature is enabled
    if (useGlobalEndpoint) {
      // Remove '/integrations' from the URL and replace with '/ai'
      const baseUrl = this.url.replace('/integrations', '');
      return axios.post(`${baseUrl}/ai/process_event`, eventPayload);
    }

    // Otherwise use hook-based endpoint
    return axios.post(
      `${this.url}/hooks/${hookId}/process_event`,
      eventPayload
    );
  }
}

export default new OpenAIAPI();
