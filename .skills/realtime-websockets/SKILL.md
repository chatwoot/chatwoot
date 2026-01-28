---
name: realtime-websockets
description: Implement real-time features using ActionCable WebSockets in Chatwoot. Use this skill when building live updates, presence indicators, typing notifications, or any feature requiring instant client-server communication.
metadata:
  author: chatwoot
  version: "1.0"
---

# Real-time WebSockets (ActionCable)

## Overview

Chatwoot uses ActionCable for real-time features like live message updates, typing indicators, and presence.

## Structure

```
app/
├── channels/
│   ├── application_cable/
│   │   ├── channel.rb
│   │   └── connection.rb
│   ├── room_channel.rb
│   ├── conversation_channel.rb
│   └── ...
├── javascript/dashboard/
│   └── helper/
│       └── actionCable.js
```

## Connection Setup

```ruby
# app/channels/application_cable/connection.rb
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      user = User.find_by(id: cookies.encrypted[:user_id])
      
      if user && valid_token?(user)
        user
      else
        reject_unauthorized_connection
      end
    end

    def valid_token?(user)
      # Token validation logic
      true
    end
  end
end
```

## Creating Channels

### Account Channel (for account-wide events)

```ruby
# app/channels/account_channel.rb
class AccountChannel < ApplicationCable::Channel
  def subscribed
    @account = find_account
    reject unless @account && authorized?

    stream_from "account_#{@account.id}"
  end

  def unsubscribed
    # Cleanup when client disconnects
  end

  private

  def find_account
    Account.find_by(id: params[:account_id])
  end

  def authorized?
    current_user.account_users.exists?(account: @account)
  end
end
```

### Conversation Channel

```ruby
# app/channels/conversation_channel.rb
class ConversationChannel < ApplicationCable::Channel
  def subscribed
    @conversation = find_conversation
    reject unless @conversation && authorized?

    stream_from conversation_stream
  end

  def typing(data)
    ActionCable.server.broadcast(
      conversation_stream,
      event: 'typing',
      data: {
        user_id: current_user.id,
        user_name: current_user.name,
        is_typing: data['typing']
      }
    )
  end

  private

  def find_conversation
    Conversation.find_by(id: params[:conversation_id])
  end

  def authorized?
    current_user.assigned_conversations.include?(@conversation) ||
      current_user.administrator?
  end

  def conversation_stream
    "conversation_#{@conversation.id}"
  end
end
```

### Presence Channel

```ruby
# app/channels/presence_channel.rb
class PresenceChannel < ApplicationCable::Channel
  def subscribed
    @account = find_account
    reject unless @account && authorized?

    stream_from "presence_#{@account.id}"
    track_presence
  end

  def unsubscribed
    untrack_presence
  end

  private

  def track_presence
    OnlineStatusTracker.track(current_user, @account)
    broadcast_presence_update
  end

  def untrack_presence
    OnlineStatusTracker.untrack(current_user, @account)
    broadcast_presence_update
  end

  def broadcast_presence_update
    ActionCable.server.broadcast(
      "presence_#{@account.id}",
      event: 'presence_update',
      data: { online_users: OnlineStatusTracker.online_users(@account) }
    )
  end
end
```

## Broadcasting Events

### From Services/Jobs

```ruby
# app/services/messages/create_service.rb
class Messages::CreateService
  def perform
    message = create_message

    broadcast_message(message)

    message
  end

  private

  def broadcast_message(message)
    ActionCable.server.broadcast(
      "conversation_#{message.conversation_id}",
      event: 'message.created',
      data: MessagePresenter.new(message).as_json
    )

    # Also broadcast to account channel
    ActionCable.server.broadcast(
      "account_#{message.account_id}",
      event: 'conversation.updated',
      data: ConversationPresenter.new(message.conversation).as_json
    )
  end
end
```

### From Dispatchers

```ruby
# app/dispatchers/async_dispatcher.rb
class AsyncDispatcher
  def dispatch(event_name, timestamp, data)
    case event_name
    when 'message.created'
      broadcast_message_created(data)
    when 'conversation.status_changed'
      broadcast_status_changed(data)
    end
  end

  private

  def broadcast_message_created(data)
    conversation = data[:conversation]
    
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      build_payload('message.created', data)
    )
  end

  def build_payload(event, data)
    {
      event: event,
      data: data,
      timestamp: Time.current.to_i
    }
  end
end
```

## Frontend Integration

### ActionCable Helper

```javascript
// app/javascript/dashboard/helper/actionCable.js
import { createConsumer } from '@rails/actioncable';

class ActionCableConnector {
  constructor(app, pubsubToken) {
    this.consumer = createConsumer(`/cable?token=${pubsubToken}`);
    this.app = app;
    this.subscriptions = {};
  }

  subscribe(channelName, params, callbacks) {
    const subscription = this.consumer.subscriptions.create(
      { channel: channelName, ...params },
      {
        received: (data) => this.handleReceived(data, callbacks),
        connected: () => callbacks.onConnected?.(),
        disconnected: () => callbacks.onDisconnected?.(),
      }
    );

    this.subscriptions[channelName] = subscription;
    return subscription;
  }

  unsubscribe(channelName) {
    const subscription = this.subscriptions[channelName];
    if (subscription) {
      subscription.unsubscribe();
      delete this.subscriptions[channelName];
    }
  }

  handleReceived(data, callbacks) {
    const { event, data: payload } = data;
    
    switch (event) {
      case 'message.created':
        callbacks.onMessageCreated?.(payload);
        break;
      case 'typing':
        callbacks.onTyping?.(payload);
        break;
      case 'presence_update':
        callbacks.onPresenceUpdate?.(payload);
        break;
    }
  }

  disconnect() {
    Object.keys(this.subscriptions).forEach(key => {
      this.unsubscribe(key);
    });
    this.consumer.disconnect();
  }
}

export default ActionCableConnector;
```

### Using in Vue Components

```vue
<script setup>
import { onMounted, onUnmounted, ref } from 'vue';
import ActionCableConnector from 'dashboard/helper/actionCable';

const props = defineProps({
  conversationId: { type: Number, required: true },
  accountId: { type: Number, required: true },
});

const isTyping = ref(false);
const typingUser = ref(null);
let cable = null;

onMounted(() => {
  cable = new ActionCableConnector();
  
  cable.subscribe('ConversationChannel', 
    { conversation_id: props.conversationId },
    {
      onMessageCreated: handleNewMessage,
      onTyping: handleTyping,
      onConnected: () => console.log('Connected to conversation'),
    }
  );
});

onUnmounted(() => {
  cable?.disconnect();
});

const handleNewMessage = (message) => {
  // Add message to store
  store.dispatch('addMessage', message);
};

const handleTyping = (data) => {
  isTyping.value = data.is_typing;
  typingUser.value = data.user_name;
};

const sendTypingIndicator = (typing) => {
  cable.subscriptions['ConversationChannel']?.perform('typing', { typing });
};
</script>

<template>
  <div>
    <span v-if="isTyping">{{ typingUser }} is typing...</span>
  </div>
</template>
```

## Event Types

| Event | Channel | Description |
|-------|---------|-------------|
| `message.created` | Conversation | New message in conversation |
| `message.updated` | Conversation | Message edited |
| `conversation.status_changed` | Account | Conversation opened/resolved |
| `conversation.assignee_changed` | Account | Agent assignment changed |
| `typing` | Conversation | User typing indicator |
| `presence_update` | Presence | Online status changed |

## Testing WebSockets

```ruby
# spec/channels/conversation_channel_spec.rb
require 'rails_helper'

RSpec.describe ConversationChannel, type: :channel do
  let(:user) { create(:user) }
  let(:conversation) { create(:conversation) }

  before do
    stub_connection current_user: user
  end

  describe '#subscribed' do
    context 'when authorized' do
      before { user.assigned_conversations << conversation }

      it 'subscribes to conversation stream' do
        subscribe(conversation_id: conversation.id)

        expect(subscription).to be_confirmed
        expect(subscription).to have_stream_from("conversation_#{conversation.id}")
      end
    end

    context 'when unauthorized' do
      it 'rejects subscription' do
        subscribe(conversation_id: conversation.id)

        expect(subscription).to be_rejected
      end
    end
  end

  describe '#typing' do
    before do
      user.assigned_conversations << conversation
      subscribe(conversation_id: conversation.id)
    end

    it 'broadcasts typing indicator' do
      expect {
        perform :typing, typing: true
      }.to have_broadcasted_to("conversation_#{conversation.id}")
        .with(hash_including(event: 'typing'))
    end
  end
end
```

## Best Practices

1. **Authorize all subscriptions** - Check user permissions
2. **Keep payloads small** - Send IDs, fetch full data from API
3. **Handle disconnections** - Implement reconnection logic
4. **Use streams wisely** - Don't over-broadcast
5. **Clean up subscriptions** - Unsubscribe on component unmount
