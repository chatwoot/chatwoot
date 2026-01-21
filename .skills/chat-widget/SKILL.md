---
name: chat-widget
description: Develop and customize the Chatwoot chat widget that embeds on customer websites. Use this skill when modifying widget appearance, behavior, SDK methods, or widget-to-server communication.
metadata:
  author: chatwoot
  version: "1.0"
---

# Chat Widget Development

## Overview

The chat widget is a standalone Vue.js application that embeds on customer websites. It communicates with the Chatwoot server via REST API and WebSockets.

## Structure

```
app/javascript/widget/
├── App.vue                 # Main widget component
├── api/                    # API client methods
├── assets/                 # Static assets
├── components/             # Widget components
├── composables/            # Vue composables
├── constants/              # Configuration constants
├── helpers/                # Utility functions
├── i18n/                   # Widget translations
├── mixins/                 # Vue mixins (legacy)
├── router.js               # Widget routing
├── store/                  # Vuex store
└── views/                  # Widget views/pages
```

## Widget Components

### Message Components

```vue
<!-- app/javascript/widget/components/UserMessage.vue -->
<script setup>
import { computed } from 'vue';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
});

const formattedTime = computed(() => {
  return new Date(props.message.created_at * 1000).toLocaleTimeString();
});
</script>

<template>
  <div class="flex justify-end mb-2">
    <div class="max-w-xs bg-woot-500 text-white rounded-lg px-4 py-2">
      <p class="text-sm">{{ message.content }}</p>
      <span class="text-xs opacity-75">{{ formattedTime }}</span>
    </div>
  </div>
</template>
```

### Agent Message

```vue
<!-- app/javascript/widget/components/AgentMessage.vue -->
<script setup>
import { computed } from 'vue';
import Avatar from './Avatar.vue';

const props = defineProps({
  message: {
    type: Object,
    required: true,
  },
  showAvatar: {
    type: Boolean,
    default: true,
  },
});

const agentName = computed(() => props.message.sender?.name || 'Agent');
</script>

<template>
  <div class="flex items-start gap-2 mb-2">
    <Avatar v-if="showAvatar" :name="agentName" size="sm" />
    <div class="max-w-xs bg-slate-100 dark:bg-slate-800 rounded-lg px-4 py-2">
      <span class="text-xs font-medium text-slate-600 dark:text-slate-400">
        {{ agentName }}
      </span>
      <p class="text-sm text-slate-900 dark:text-slate-100">
        {{ message.content }}
      </p>
    </div>
  </div>
</template>
```

## Widget Store (Vuex)

```javascript
// app/javascript/widget/store/modules/conversation.js
import MessageAPI from '../../api/message';

const state = {
  conversations: {},
  currentConversationId: null,
  isFetching: false,
};

const getters = {
  getCurrentConversation: (state) => {
    return state.conversations[state.currentConversationId] || {};
  },
  getMessages: (state, getters) => {
    return getters.getCurrentConversation.messages || [];
  },
};

const mutations = {
  SET_CONVERSATION(state, { id, data }) {
    state.conversations[id] = data;
  },
  ADD_MESSAGE(state, { conversationId, message }) {
    const conversation = state.conversations[conversationId];
    if (conversation) {
      conversation.messages.push(message);
    }
  },
  SET_FETCHING(state, status) {
    state.isFetching = status;
  },
};

const actions = {
  async fetchConversation({ commit }, conversationId) {
    commit('SET_FETCHING', true);
    try {
      const { data } = await MessageAPI.getConversation(conversationId);
      commit('SET_CONVERSATION', { id: conversationId, data });
    } finally {
      commit('SET_FETCHING', false);
    }
  },

  async sendMessage({ commit, state }, { content, attachments }) {
    const message = await MessageAPI.create({
      conversationId: state.currentConversationId,
      content,
      attachments,
    });
    commit('ADD_MESSAGE', {
      conversationId: state.currentConversationId,
      message: message.data,
    });
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};
```

## Widget API

```javascript
// app/javascript/widget/api/message.js
import endPoints from './endPoints';
import { API } from './index';

export default {
  getConversation(conversationId) {
    return API.get(endPoints.getConversation(conversationId));
  },

  create({ conversationId, content, attachments }) {
    const formData = new FormData();
    formData.append('content', content);
    
    if (attachments?.length) {
      attachments.forEach((file) => {
        formData.append('attachments[]', file);
      });
    }

    return API.post(endPoints.createMessage(conversationId), formData);
  },

  toggleStatus(conversationId) {
    return API.post(endPoints.toggleStatus(conversationId));
  },
};
```

## SDK Integration

### Website Installation

```html
<script>
  (function(d,t) {
    var BASE_URL = "https://app.chatwoot.com";
    var g = d.createElement(t), s = d.getElementsByTagName(t)[0];
    g.src = BASE_URL + "/packs/js/sdk.js";
    g.defer = true;
    g.async = true;
    s.parentNode.insertBefore(g, s);
    g.onload = function() {
      window.chatwootSDK.run({
        websiteToken: 'YOUR_WEBSITE_TOKEN',
        baseUrl: BASE_URL
      });
    }
  })(document, "script");
</script>
```

### SDK Methods

```javascript
// app/javascript/sdk/sdk.js

// Set user information
window.$chatwoot.setUser('user_id', {
  email: 'user@example.com',
  name: 'John Doe',
  phone_number: '+1234567890',
  custom_attributes: {
    plan: 'premium',
    signup_date: '2024-01-15',
  },
});

// Set custom attributes
window.$chatwoot.setCustomAttributes({
  accountId: 123,
  pricingPlan: 'enterprise',
});

// Delete custom attributes
window.$chatwoot.deleteCustomAttribute('pricingPlan');

// Set language
window.$chatwoot.setLocale('es');

// Toggle widget visibility
window.$chatwoot.toggle();       // Toggle
window.$chatwoot.toggle('open'); // Open
window.$chatwoot.toggle('close'); // Close

// Set conversation custom attributes
window.$chatwoot.setConversationCustomAttributes({
  page: 'checkout',
  order_value: 99.99,
});

// Reset session
window.$chatwoot.reset();
```

### SDK Events

```javascript
// Listen for widget events
window.addEventListener('chatwoot:ready', function() {
  console.log('Widget is ready');
});

window.addEventListener('chatwoot:on-message', function(event) {
  console.log('New message:', event.detail);
});

window.addEventListener('chatwoot:error', function(event) {
  console.error('Widget error:', event.detail);
});
```

## Widget Customization

### Appearance Settings

```javascript
window.chatwootSettings = {
  hideMessageBubble: false,
  position: 'right', // 'left' or 'right'
  locale: 'en',
  type: 'standard', // 'standard' or 'expanded_bubble'
  darkMode: 'auto', // 'auto', 'light', or 'dark'
  
  // Custom launcher
  launcherTitle: 'Chat with us',
  
  // Pre-chat form
  preChatFormOptions: {
    customFields: [
      {
        name: 'email',
        type: 'email',
        required: true,
        placeholder: 'Enter your email',
      },
    ],
  },
};
```

### CSS Customization

Widget uses CSS variables for theming:

```css
:root {
  --woot-widget-bubble-color: #1f93ff;
  --woot-widget-bubble-position: right;
}
```

## Testing Widget

```javascript
// spec/javascript/widget/components/UserMessage.spec.js
import { describe, it, expect } from 'vitest';
import { mount } from '@vue/test-utils';
import UserMessage from 'widget/components/UserMessage.vue';

describe('UserMessage', () => {
  const message = {
    id: 1,
    content: 'Hello!',
    created_at: 1704067200,
    message_type: 'outgoing',
  };

  it('renders message content', () => {
    const wrapper = mount(UserMessage, {
      props: { message },
    });

    expect(wrapper.text()).toContain('Hello!');
  });
});
```

## Widget-Server Communication

### WebSocket Connection

```javascript
// app/javascript/widget/helpers/actionCable.js
import { createConsumer } from '@rails/actioncable';

export const connectToChannel = (pubsubToken, callbacks) => {
  const consumer = createConsumer(
    `/cable?token=${pubsubToken}`
  );

  return consumer.subscriptions.create(
    { channel: 'RoomChannel', pubsub_token: pubsubToken },
    {
      received(data) {
        if (data.event === 'message.created') {
          callbacks.onMessage(data.data);
        }
        if (data.event === 'typing_on') {
          callbacks.onTyping(true);
        }
        if (data.event === 'typing_off') {
          callbacks.onTyping(false);
        }
      },
    }
  );
};
```

## Pre-Chat Form

```vue
<!-- app/javascript/widget/components/PreChatForm.vue -->
<script setup>
import { ref } from 'vue';
import { useStore } from 'vuex';

const store = useStore();
const formData = ref({
  name: '',
  email: '',
  message: '',
});

const submitForm = async () => {
  await store.dispatch('contacts/setContact', {
    name: formData.value.name,
    email: formData.value.email,
  });
  
  await store.dispatch('conversation/sendMessage', {
    content: formData.value.message,
  });
};
</script>

<template>
  <form @submit.prevent="submitForm" class="p-4 space-y-4">
    <input
      v-model="formData.name"
      type="text"
      :placeholder="$t('PRE_CHAT_FORM.NAME')"
      class="w-full px-3 py-2 border rounded-md"
      required
    />
    <input
      v-model="formData.email"
      type="email"
      :placeholder="$t('PRE_CHAT_FORM.EMAIL')"
      class="w-full px-3 py-2 border rounded-md"
      required
    />
    <textarea
      v-model="formData.message"
      :placeholder="$t('PRE_CHAT_FORM.MESSAGE')"
      class="w-full px-3 py-2 border rounded-md"
      rows="3"
      required
    />
    <button
      type="submit"
      class="w-full py-2 bg-woot-500 text-white rounded-md hover:bg-woot-600"
    >
      {{ $t('PRE_CHAT_FORM.SUBMIT') }}
    </button>
  </form>
</template>
```
