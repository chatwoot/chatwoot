# Epic 21: Frontend WebSocket Client Adaptation

## Overview
- **Duration**: 1 week
- **Complexity**: Medium
- **Dependencies**: Epic 19 (WebSocket server)
- **Team Size**: 2 engineers
- **Can Parallelize**: Yes (by module)

## Scope: ActionCable → Socket.io Client

### 1. Replace ActionCable Client
- Remove ActionCable dependency
- Install Socket.io client
- Setup connection configuration

### 2. Connection Management
- Connection initialization
- Authentication (JWT)
- Reconnection logic
- Connection state management

### 3. Room/Channel Subscriptions
- Update room subscriptions
- Update channel subscriptions
- Update event handlers

### 4. Event Handlers
- Message received
- Conversation updated
- Notification received
- Presence updated (online/offline)
- Typing indicators
- Agent status changes

### 5. State Management
- Update Vuex actions for real-time events
- Update component reactivity
- Handle connection state in store

### 6. Testing
- Connection testing
- Event testing
- Reconnection testing
- Error handling testing

## Example Migration

**Before (ActionCable):**
```javascript
import consumer from './consumer';

consumer.subscriptions.create(
  { channel: 'RoomChannel', pubsub_token: token },
  {
    received(data) {
      // Handle data
    },
  }
);
```

**After (Socket.io):**
```javascript
import io from 'socket.io-client';

const socket = io('ws://localhost:3000', {
  auth: { token: localStorage.getItem('token') },
});

socket.on('message.created', (data) => {
  // Handle data
});

socket.emit('conversation:join', { conversationId });
```

## Parallel Strategy
- Team A: Dashboard WebSocket
- Team B: Widget WebSocket

## Estimated Time
50 hours / 2 engineers ≈ 1 week

---

**Status**: 🟡 Ready (after Epic 19)
