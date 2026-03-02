import { createConsumer } from '@rails/actioncable';

/**
 * Lightweight ActionCable subscription for the LlmChannel.
 * Streams llm.chunk / llm.complete / llm.error events.
 *
 * Usage:
 *   const cable = new LlmCableSubscription({
 *     pubsubToken: '...',
 *     accountId: 123,
 *     onChunk: ({ request_id, delta }) => ...,
 *     onComplete: ({ request_id, usage }) => ...,
 *     onError: ({ request_id, error }) => ...,
 *   });
 *   cable.connect();
 *   cable.disconnect();
 */
class LlmCableSubscription {
  constructor({ pubsubToken, accountId, onChunk, onComplete, onError }) {
    this.pubsubToken = pubsubToken;
    this.accountId = accountId;
    this.onChunk = onChunk || (() => {});
    this.onComplete = onComplete || (() => {});
    this.onError = onError || (() => {});
    this.consumer = null;
    this.subscription = null;
  }

  connect() {
    if (this.subscription) return;

    this.consumer = createConsumer();
    this.subscription = this.consumer.subscriptions.create(
      {
        channel: 'LlmChannel',
        pubsub_token: this.pubsubToken,
        account_id: this.accountId,
      },
      {
        received: message => this.handleMessage(message),
        disconnected: () => this.handleDisconnect(),
      }
    );
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe();
      this.subscription = null;
    }
    if (this.consumer) {
      this.consumer.disconnect();
      this.consumer = null;
    }
  }

  handleMessage(message) {
    const { event, data } = message;
    switch (event) {
      case 'llm.chunk':
        this.onChunk(data);
        break;
      case 'llm.complete':
        this.onComplete(data);
        break;
      case 'llm.error':
        this.onError(data);
        break;
      default:
        break;
    }
  }

  // eslint-disable-next-line class-methods-use-this
  handleDisconnect() {
    // Auto-reconnect is handled by @rails/actioncable internally
  }
}

export default LlmCableSubscription;
