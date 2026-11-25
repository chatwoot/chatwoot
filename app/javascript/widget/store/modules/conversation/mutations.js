import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { findUndeliveredMessage } from './helpers';

// typing_off can arrive before the server's copy of the contact's message
// replaces the temporary one, so keep the dismissal on the replacement.
const carryTypingDismissal = ($state, tempId, id) => {
  if ($state.uiFlags?.typingDismissedForMessageId === tempId) {
    $state.uiFlags.typingDismissedForMessageId = id;
  }
};

const lastMessageId = conversations =>
  Object.values(conversations).pop()?.id ?? null;

export const mutations = {
  clearConversations($state) {
    $state.conversations = {};
    $state.pendingCustomAttributes = {};
    $state.pendingLabels = [];
  },
  pushMessageToConversation($state, message) {
    const { id, status, message_type: type } = message;

    const messagesInbox = $state.conversations;
    const isMessageIncoming = type === MESSAGE_TYPE.INCOMING;
    const isTemporaryMessage = status === 'in_progress';

    if (!isMessageIncoming || isTemporaryMessage) {
      messagesInbox[id] = message;
      return;
    }

    const [messageInConversation] = findUndeliveredMessage(
      messagesInbox,
      message
    );
    if (!messageInConversation) {
      messagesInbox[id] = message;
    } else {
      // [VITE] instead of leaving undefined behind, we remove it completely
      // remove the temporary message and replace it with the new message
      // messagesInbox[messageInConversation.id] = undefined;
      delete messagesInbox[messageInConversation.id];
      messagesInbox[id] = message;
      carryTypingDismissal($state, messageInConversation.id, id);
    }
  },

  updateAttachmentMessageStatus($state, { message, tempId }) {
    const { id } = message;
    const messagesInbox = $state.conversations;

    const messageInConversation = messagesInbox[tempId];

    if (messageInConversation) {
      // [VITE] instead of leaving undefined behind, we remove it completely
      // remove the temporary message and replace it with the new message
      // messagesInbox[tempId] = undefined;
      delete messagesInbox[tempId];
      messagesInbox[id] = { ...message };
      carryTypingDismissal($state, tempId, id);
    }
  },

  setConversationUIFlag($state, uiFlags) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...uiFlags,
    };
  },

  setConversationListLoading($state, status) {
    $state.uiFlags.isFetchingList = status;
  },

  setMessagesInConversation($state, payload) {
    if (!payload.length) {
      $state.uiFlags.allMessagesLoaded = true;
      return;
    }

    payload.forEach(message => {
      $state.conversations[message.id] = message;
    });
  },

  setMissingMessagesInConversation($state, payload) {
    $state.conversation = payload;
  },

  updateMessage($state, { id, content_attributes }) {
    $state.conversations[id] = {
      ...$state.conversations[id],
      content_attributes: {
        ...($state.conversations[id].content_attributes || {}),
        ...content_attributes,
      },
    };
  },

  updateMessageMeta($state, { id, meta }) {
    const message = $state.conversations[id];
    if (!message) return;

    const newMeta = message.meta ? { ...message.meta, ...meta } : { ...meta };
    message.meta = { ...newMeta };
  },

  deleteMessage($state, id) {
    delete $state.conversations[id];
    carryTypingDismissal($state, id, lastMessageId($state.conversations));
    // [VITE] In Vue 3 proxy objects, we can't delete properties by setting them to undefined
    // Instead, we have to use the delete operator
    // $state.conversations[id] = undefined;
  },

  toggleAgentTypingStatus($state, { status, dismiss = false }) {
    $state.uiFlags.isAgentTyping = status === 'on';
    if (status === 'on') {
      // A new typing session supersedes an earlier typing_off.
      $state.uiFlags.typingDismissedForMessageId = null;
    } else if (dismiss) {
      $state.uiFlags.typingDismissedForMessageId = lastMessageId(
        $state.conversations
      );
    }
  },

  setMetaUserLastSeenAt($state, lastSeen) {
    $state.meta.userLastSeenAt = lastSeen;
  },

  setLastMessageId($state) {
    const { conversations } = $state;
    const lastMessage = Object.values(conversations).pop();
    if (!lastMessage) return;
    const { id } = lastMessage;
    $state.lastMessageId = id;
  },

  setPendingCustomAttributes($state, data) {
    $state.pendingCustomAttributes = {
      ...$state.pendingCustomAttributes,
      ...data,
    };
  },

  setPendingLabels($state, label) {
    if (!$state.pendingLabels.includes(label)) {
      $state.pendingLabels.push(label);
    }
  },

  removePendingCustomAttribute($state, key) {
    const { [key]: _, ...rest } = $state.pendingCustomAttributes;
    $state.pendingCustomAttributes = rest;
  },

  removePendingLabel($state, label) {
    $state.pendingLabels = $state.pendingLabels.filter(l => l !== label);
  },

  clearPendingConversationMetadata($state) {
    $state.pendingCustomAttributes = {};
    $state.pendingLabels = [];
  },
};
