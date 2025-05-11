import { createConsumer } from '@rails/actioncable';

class CopilotActionCableConnector {
  constructor(
    { accountId, userId, onDisconnect, onCopilotResponse },
    websocketHost = ''
  ) {
    const websocketURL = websocketHost ? `${websocketHost}/cable` : undefined;

    this.consumer = createConsumer(websocketURL);
    this.subscription = this.consumer.subscriptions.create(
      {
        channel: 'CopilotChannel',
        account_id: accountId,
        user_id: userId,
      },
      {
        received: this.onReceived,
        disconnected: onDisconnect,
      }
    );

    this.events = {
      'copilot.response': onCopilotResponse,
    };
  }

  onReceived = ({ event, data } = {}) => {
    if (this.events[event] && typeof this.events[event] === 'function') {
      this.events[event](data);
    }
  };

  disconnect() {
    this.subscription.unsubscribe();
    this.consumer.disconnect();
  }

  sendMessage({ message, assistantId, conversationId, previousHistory }) {
    this.subscription.perform('message', {
      message,
      assistant_id: assistantId,
      conversation_id: conversationId,
      previous_history: previousHistory,
    });
  }
}

export default CopilotActionCableConnector;
