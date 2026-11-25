<script setup>
import { computed, reactive } from 'vue';
import Message from './Message.vue';
import CampaignMessage from './CampaignMessage.vue';
import { MESSAGE_TYPES } from './constants.js';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { useMapGetter } from 'dashboard/composables/store.js';
import MessageApi from 'dashboard/api/inbox/message.js';

/**
 * Props definition for the component
 * @typedef {Object} Props
 * @property {Array} readMessages - Array of read messages
 * @property {Array} unReadMessages - Array of unread messages
 * @property {Number} currentUserId - ID of the current user
 * @property {Boolean} isAnEmailChannel - Whether this is an email channel
 * @property {Object} inboxSupportsReplyTo - Inbox reply support configuration
 * @property {Boolean} inboxSupportsEdit - Whether the inbox supports message editing
 * @property {Array} messages - Array of all messages [These are not in camelcase]
 */
const props = defineProps({
  currentUserId: {
    type: Number,
    required: true,
  },
  firstUnreadId: {
    type: [Number, String],
    default: null,
  },
  isAnEmailChannel: {
    type: Boolean,
    default: false,
  },
  inboxSupportsReplyTo: {
    type: Object,
    default: () => ({ incoming: false, outgoing: false }),
  },
  inboxSupportsEdit: {
    type: Boolean,
    default: false,
  },
  inboxSupportsReactions: {
    type: Boolean,
    default: false,
  },
  messages: {
    type: Array,
    default: () => [],
  },
  campaignHistory: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['retry', 'toggleReaction']);

const allMessages = computed(() => {
  return useCamelCase(props.messages, {
    deep: true,
    stopPaths: [
      'content_attributes.translations',
      'content_attributes.whatsapp_flow_response.response_json',
    ],
  });
});

const reactionsByMessageId = computed(() => {
  // Keep only the latest reaction per (originalMessage, sender) and drop
  // entries flagged as deleted or with empty content.
  // Normalize sender_type casing: REST jbuilder doesn't expose `sender_type`
  // (only nested `sender.type` in lowercase), while ActionCable's push_event_data
  // includes Rails class names ('User', 'Contact'). We unify on lowercase so
  // dedup keys and "isMine" comparisons stay consistent across both transports.
  const senderTypeOf = msg =>
    (msg.senderType ?? msg.sender?.type ?? '').toLowerCase();

  // Multi-device echoes (the agent reacts from the WhatsApp mobile app on the
  // same number connected to the inbox) arrive as outgoing reactions without an
  // agent. Treat them as "ours" so they show up in the chip and the preview
  // instead of falling through as ghosts.
  const isOwnInboxReaction = msg => {
    const sid = msg.senderId ?? msg.sender?.id;
    return msg.messageType === 1 && sid == null;
  };

  // Collapse "agent reacted via Chatwoot" and "agent reacted via the connected
  // phone" into the same logical actor so the chip never double-counts the
  // current user. The controller and MessagesView already treat both shapes
  // as the same toggle target.
  const isSelfReaction = msg => {
    if (isOwnInboxReaction(msg)) return true;
    const senderId = msg.senderId ?? msg.sender?.id;
    return senderTypeOf(msg) === 'user' && senderId === props.currentUserId;
  };

  // Build a sourceId → id lookup so reactions that only carry
  // `inReplyToExternalId` (WhatsApp echo/phone-originated) can still resolve
  // to a visible target when `inReplyTo` wasn't populated at save time.
  const messageIdBySourceId = new Map(
    allMessages.value.filter(m => !!m.sourceId).map(m => [m.sourceId, m.id])
  );

  const latestPerKey = new Map();
  allMessages.value.forEach(msg => {
    if (!msg.contentAttributes?.isReaction) return;
    const originalId =
      msg.contentAttributes?.inReplyTo ??
      messageIdBySourceId.get(msg.contentAttributes?.inReplyToExternalId);
    if (!originalId) return;
    const senderId = msg.senderId ?? msg.sender?.id;
    const senderType = senderTypeOf(msg);
    const selfReaction = isSelfReaction(msg);
    if (!selfReaction && (senderId == null || !senderType)) return;
    // Each multi-device toggle creates a fresh Message (the backend can't
    // collapse them in place because there is no agent to scope by), so
    // dedupe them under a single key per target message.
    const key = selfReaction
      ? `${originalId}|self|self`
      : `${originalId}|${senderType}|${senderId}`;
    const prev = latestPerKey.get(key);
    // Use <= so a later iteration wins on timestamp ties. Cable payloads carry
    // second-resolution createdAt, so two toggles in the same second need a
    // deterministic later-wins rule to avoid pinning the chip to a stale row.
    if (!prev || (prev.createdAt ?? 0) <= (msg.createdAt ?? 0)) {
      latestPerKey.set(key, msg);
    }
  });

  const map = new Map();
  latestPerKey.forEach(reaction => {
    if (reaction.contentAttributes?.deleted) return;
    if (!reaction.content) return;
    // Mirror the first pass: an echoed reaction may carry only
    // inReplyToExternalId, so resolve via the sourceId lookup before giving up.
    const originalId =
      reaction.contentAttributes.inReplyTo ??
      messageIdBySourceId.get(reaction.contentAttributes?.inReplyToExternalId);
    if (!originalId) return;
    if (!map.has(originalId)) map.set(originalId, []);
    map.get(originalId).push({
      id: reaction.id,
      emoji: reaction.content,
      senderId: reaction.senderId ?? reaction.sender?.id,
      senderType: senderTypeOf(reaction),
      sender: reaction.sender,
      messageType: reaction.messageType,
    });
  });
  return map;
});

const visibleMessages = computed(() => {
  return allMessages.value.filter(msg => !msg.contentAttributes?.isReaction);
});

// firstUnreadId can point to a reaction (filtered out of visibleMessages),
// in which case the unread separator would never render. Anchor it to the
// first visible message at or after that id so the divider always shows up
// next to a real bubble.
const effectiveFirstUnreadId = computed(() => {
  if (!props.firstUnreadId) return null;
  const direct = visibleMessages.value.find(
    msg => msg.id === props.firstUnreadId
  );
  if (direct) return direct.id;
  const fallback = visibleMessages.value.find(
    msg => msg.id >= props.firstUnreadId
  );
  return fallback?.id ?? null;
});

const currentChat = useMapGetter('getSelectedChat');

const isGroupConversation = computed(
  () => currentChat.value?.group_type === 'group'
);

// Reactions stay out of the timeline: they render as chips on the message they
// point at, not as bubbles of their own.
const timeline = computed(() => {
  const messages = visibleMessages.value.map(message => ({
    key: `message-${message.id}`,
    createdAt: message.createdAt,
    message,
  }));
  if (!props.campaignHistory.length) return messages;

  return [
    ...messages,
    ...props.campaignHistory.map(recipient => ({
      key: `campaign-${recipient.id}`,
      createdAt: recipient.sent_at,
      recipient,
    })),
  ].sort((a, b) => a.createdAt - b.createdAt);
});

// Cache for fetched reply messages to avoid duplicate API calls
const fetchedReplyMessages = reactive(new Map());

/**
 * Fetches a specific message from the API by trying to get messages around it
 * @param {number} messageId - The ID of the message to fetch
 * @param {number} conversationId - The ID of the conversation
 * @returns {Promise<Object|null>} - The fetched message or null if not found/error
 */
const fetchReplyMessage = async (messageId, conversationId) => {
  // Return cached result if already fetched
  if (fetchedReplyMessages.has(messageId)) {
    return fetchedReplyMessages.get(messageId);
  }

  try {
    const response = await MessageApi.getPreviousMessages({
      conversationId,
      before: messageId + 100,
      after: messageId - 100,
    });

    const messages = response.data?.payload || [];
    const targetMessage = messages.find(msg => msg.id === messageId);

    if (targetMessage) {
      const camelCaseMessage = useCamelCase(targetMessage);
      fetchedReplyMessages.set(messageId, camelCaseMessage);
      return camelCaseMessage;
    }

    // Cache null result to avoid repeated API calls
    fetchedReplyMessages.set(messageId, null);
    return null;
  } catch (error) {
    fetchedReplyMessages.set(messageId, null);
    return null;
  }
};

/**
 * Determines if a message should be grouped with the next message
 * @param {Object} current - Current message
 * @param {Object} next - Next message, absent at a campaign entry or the end
 * @returns {Boolean} - Whether the message should be grouped with next
 */
const shouldGroupWithNext = (current, next) => {
  if (!next || next.status === 'failed') return false;

  const nextSenderId = next.senderId ?? next.sender?.id;
  const currentSenderId = current.senderId ?? current.sender?.id;
  const hasSameSender = nextSenderId === currentSenderId;

  const nextMessageType = next.messageType;
  const currentMessageType = current.messageType;

  const areBothTemplates =
    nextMessageType === MESSAGE_TYPES.TEMPLATE &&
    currentMessageType === MESSAGE_TYPES.TEMPLATE;

  if (!hasSameSender || areBothTemplates) return false;

  if (currentMessageType !== nextMessageType) return false;

  // Check if messages are in the same minute by rounding down to nearest minute
  return Math.floor(next.createdAt / 60) === Math.floor(current.createdAt / 60);
};

/**
 * Gets the message that was replied to
 * @param {Object} parentMessage - The message containing the reply reference
 * @returns {Object|null} - The message being replied to, or null if not found
 */
const getInReplyToMessage = parentMessage => {
  if (!parentMessage) return null;

  const inReplyToMessageId =
    parentMessage.contentAttributes?.inReplyTo ??
    parentMessage.content_attributes?.in_reply_to;

  if (!inReplyToMessageId) return null;

  // Try to find in current messages first
  let replyMessage = props.messages?.find(msg => msg.id === inReplyToMessageId);

  // Then try store messages
  if (!replyMessage && currentChat.value?.messages) {
    replyMessage = currentChat.value.messages.find(
      msg => msg.id === inReplyToMessageId
    );
  }

  // Then check fetch cache
  if (!replyMessage && fetchedReplyMessages.has(inReplyToMessageId)) {
    replyMessage = fetchedReplyMessages.get(inReplyToMessageId);
  }

  // If still not found and we have conversation context, fetch it
  if (!replyMessage && currentChat.value?.id) {
    fetchReplyMessage(inReplyToMessageId, currentChat.value.id);
    return null; // Let UI handle loading state
  }

  return replyMessage ? useCamelCase(replyMessage) : null;
};
</script>

<template>
  <ul class="px-4 bg-n-surface-1">
    <slot name="beforeAll" />
    <template v-for="(entry, index) in timeline" :key="entry.key">
      <slot
        v-if="
          effectiveFirstUnreadId && entry.message?.id === effectiveFirstUnreadId
        "
        name="unreadBadge"
      />
      <CampaignMessage v-if="entry.recipient" :recipient="entry.recipient" />
      <Message
        v-else
        v-bind="entry.message"
        :is-email-inbox="isAnEmailChannel"
        :in-reply-to="getInReplyToMessage(entry.message)"
        :group-with-next="
          shouldGroupWithNext(entry.message, timeline[index + 1]?.message)
        "
        :group-with-previous="
          !!timeline[index - 1]?.message &&
          shouldGroupWithNext(timeline[index - 1].message, entry.message)
        "
        :is-group-conversation="isGroupConversation"
        :inbox-supports-reply-to="inboxSupportsReplyTo"
        :inbox-supports-edit="inboxSupportsEdit"
        :inbox-supports-reactions="inboxSupportsReactions"
        :reactions="reactionsByMessageId.get(entry.message.id) || []"
        :current-user-id="currentUserId"
        data-clarity-mask="True"
        @retry="emit('retry', entry.message)"
        @toggle-reaction="emit('toggleReaction', $event)"
      />
    </template>
    <slot name="after" />
  </ul>
</template>
