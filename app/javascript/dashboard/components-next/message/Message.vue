<script setup>
import { onMounted, onUnmounted, computed, ref, toRefs } from 'vue';
import { useTimeoutFn } from '@vueuse/core';
import { provideMessageContext } from './provider.js';
import { isContactSide } from 'dashboard/store/modules/conversations/helpers';
import { useTrack } from 'dashboard/composables';
import { useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { emitter } from 'shared/helpers/mitt';
import { useI18n } from 'vue-i18n';
import { useRoute, useRouter } from 'vue-router';
import { LocalStorage } from 'shared/helpers/localStorage';
import { ACCOUNT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import {
  canDeleteMessages,
  getUserRole,
} from 'dashboard/helper/permissionsHelper.js';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  MESSAGE_TYPES,
  ATTACHMENT_TYPES,
  MESSAGE_VARIANTS,
  SENDER_TYPES,
  ORIENTATION,
  MESSAGE_STATUS,
  CONTENT_TYPES,
} from './constants';

import Avatar from 'next/avatar/Avatar.vue';

import TextBubble from './bubbles/Text/Index.vue';
import ActivityBubble from './bubbles/Activity.vue';
import ImageBubble from './bubbles/Image.vue';
import FileBubble from './bubbles/File.vue';
import AudioBubble from './bubbles/Audio.vue';
import VideoBubble from './bubbles/Video.vue';
import VideoNoteBubble from './bubbles/VideoNote.vue';
import EmbedBubble from './bubbles/Embed.vue';
import FallbackBubble from './bubbles/Fallback.vue';
import InstagramStoryBubble from './bubbles/InstagramStory.vue';
import EmailBubble from './bubbles/Email/Index.vue';
import UnsupportedBubble from './bubbles/Unsupported.vue';
import RichMessageBubble from './bubbles/RichMessage.vue';
import ContactBubble from './bubbles/Contact.vue';
import DyteBubble from './bubbles/Dyte.vue';
import LocationBubble from './bubbles/Location.vue';
import CSATBubble from './bubbles/CSAT.vue';
import FormBubble from './bubbles/Form.vue';
import VoiceCallBubble from './bubbles/VoiceCall.vue';
import WhatsappFlowResponseBubble from './bubbles/WhatsappFlowResponse.vue';

import MessageError from './MessageError.vue';
import ForwardEmailPanel from './forward/ForwardEmailPanel.vue';
import ForwardedEmailBanner from './forward/ForwardedEmailBanner.vue';
import ContextMenu from 'dashboard/modules/conversations/components/MessageContextMenu.vue';
import EmojiReactionPicker from './EmojiReactionPicker.vue';
import ReactionDisplay from './ReactionDisplay.vue';
import { useBranding } from 'shared/composables/useBranding';
import { useTranslations } from 'dashboard/composables/useTranslations';

/**
 * @typedef {Object} Attachment
 * @property {number} id - Unique identifier for the attachment
 * @property {number} messageId - ID of the associated message
 * @property {'image'|'audio'|'video'|'file'|'location'|'fallback'|'share'|'story_mention'|'contact'|'ig_reel'} fileType - Type of the attachment (file or image)
 * @property {number} accountId - ID of the associated account
 * @property {string|null} extension - File extension
 * @property {string} dataUrl - URL to access the full attachment data
 * @property {string} thumbUrl - URL to access the thumbnail version
 * @property {number} fileSize - Size of the file in bytes
 * @property {number|null} width - Width of the image if applicable
 * @property {number|null} height - Height of the image if applicable
 */

/**
 * @typedef {Object} Sender
 * @property {Object} additional_attributes - Additional attributes of the sender
 * @property {Object} custom_attributes - Custom attributes of the sender
 * @property {string} email - Email of the sender
 * @property {number} id - ID of the sender
 * @property {string|null} identifier - Identifier of the sender
 * @property {string} name - Name of the sender
 * @property {string|null} phone_number - Phone number of the sender
 * @property {string} thumbnail - Thumbnail URL of the sender
 * @property {string} type - Type of sender
 */

/**
 * @typedef {Object} ContentAttributes
 * @property {string} externalError - an error message to be shown if the message failed to send
 */

/**
 * @typedef {Object} Props
 * @property {('sent'|'delivered'|'read'|'failed'|'progress')} status - The delivery status of the message
 * @property {ContentAttributes} [contentAttributes={}] - Additional attributes of the message content
 * @property {Attachment[]} [attachments=[]] - The attachments associated with the message
 * @property {Sender|null} [sender=null] - The sender information
 * @property {boolean} [private=false] - Whether the message is private
 * @property {number|null} [senderId=null] - The ID of the sender
 * @property {number} createdAt - Timestamp when the message was created
 * @property {number} currentUserId - The ID of the current user
 * @property {number} id - The unique identifier for the message
 * @property {number} messageType - The type of message (must be one of MESSAGE_TYPES)
 * @property {string|null} [error=null] - Error message if the message failed to send
 * @property {string|null} [senderType=null] - The type of the sender
 * @property {string} content - The message content
 * @property {boolean} [groupWithNext=false] - Whether the message should be grouped with the next message
 * @property {Object|null} [inReplyTo=null] - The message to which this message is a reply
 * @property {boolean} [isEmailInbox=false] - Whether the message is from an email inbox
 * @property {number} conversationId - The ID of the conversation to which the message belongs
 * @property {number} inboxId - The ID of the inbox to which the message belongs
 * @property {Object} [additionalAttributes={}] - Additional attributes of the message
 */

// eslint-disable-next-line vue/define-macros-order
const props = defineProps({
  id: { type: [Number, String], required: true },
  messageType: {
    type: Number,
    required: true,
    validator: value => Object.values(MESSAGE_TYPES).includes(value),
  },
  status: {
    type: String,
    required: true,
    validator: value => Object.values(MESSAGE_STATUS).includes(value),
  },
  attachments: { type: Array, default: () => [] },
  call: { type: Object, default: null }, // eslint-disable-line vue/no-unused-properties
  content: { type: String, default: null },
  contentAttributes: { type: Object, default: () => ({}) },
  contentType: {
    type: String,
    default: 'text',
    validator: value => Object.values(CONTENT_TYPES).includes(value),
  },
  // eslint-disable-next-line vue/no-unused-properties
  additionalAttributes: { type: Object, default: () => ({}) },
  conversationId: { type: Number, required: true },
  createdAt: { type: Number, required: true }, // eslint-disable-line vue/no-unused-properties
  currentUserId: { type: Number, required: true }, // eslint-disable-line vue/no-unused-properties
  groupWithNext: { type: Boolean, default: false },
  groupWithPrevious: { type: Boolean, default: false },
  inboxId: { type: Number, default: null }, // eslint-disable-line vue/no-unused-properties
  inboxSupportsReplyTo: { type: Object, default: () => ({}) },
  inboxSupportsEdit: { type: Boolean, default: false },
  inReplyTo: { type: Object, default: null }, // eslint-disable-line vue/no-unused-properties
  isEmailInbox: { type: Boolean, default: false },
  isGroupConversation: { type: Boolean, default: false },
  private: { type: Boolean, default: false },
  sender: { type: Object, default: null },
  senderId: { type: Number, default: null },
  senderType: { type: String, default: null },
  sourceId: { type: String, default: '' }, // eslint-disable-line vue/no-unused-properties
  reactions: { type: Array, default: () => [] },
  inboxSupportsReactions: { type: Boolean, default: false },
});

const emit = defineEmits(['retry', 'toggleReaction']);

const contextMenuPosition = ref({});
const showBackgroundHighlight = ref(false);
const showContextMenu = ref(false);
const reactionPickerOpen = ref(false);
const showForwardEmail = ref(false);
const forwardEmailPosition = ref({});
const { t } = useI18n();
const route = useRoute();
const inboxGetter = useMapGetter('inboxes/getInbox');
const inbox = computed(() => inboxGetter.value(props.inboxId) || {});
const router = useRouter();
const isOnChatwootCloud = useMapGetter('globalConfig/isOnChatwootCloud');
const { replaceInstallationName } = useBranding();
const { accountId: currentAccountId, currentAccount } = useAccount();
const currentUser = useMapGetter('getCurrentUser');

// Mirrors `MessagePolicy#destroy?`: hiding the option is a convenience, the
// endpoint enforces the same rule.
const canDeleteMessage = computed(() =>
  canDeleteMessages({
    userRole: getUserRole(currentUser.value, currentAccountId.value),
    accountSettings: currentAccount.value?.settings || {},
  })
);
const autoTranslate = useMapGetter('getAutoTranslate');
const translationState = useMapGetter('getMessageTranslationState');
const showingOriginal = ref(false);
const contactSide = computed(() =>
  isContactSide(props.messageType, props.sender?.type ?? props.senderType)
);
const { translationContent } = useTranslations(
  computed(() => props.contentAttributes),
  contactSide
);
const displayedContent = computed(() =>
  showingOriginal.value || !translationContent.value
    ? props.content
    : translationContent.value
);

const isAutoTranslated = computed(() => {
  const { pending } = translationState.value(props.id);
  return (
    !!autoTranslate.value.language && (!!translationContent.value || pending)
  );
});

const isCaptainMessage = computed(() => {
  const senderType = props.sender?.type ?? props.senderType;
  return senderType === SENDER_TYPES.CAPTAIN_ASSISTANT;
});

/**
 * Computes the message variant based on props
 * @type {import('vue').ComputedRef<'user'|'agent'|'activity'|'private'|'bot'|'template'>}
 */
const variant = computed(() => {
  if (props.private) return MESSAGE_VARIANTS.PRIVATE;

  if (props.isEmailInbox) {
    const emailInboxTypes = [MESSAGE_TYPES.INCOMING, MESSAGE_TYPES.OUTGOING];
    if (emailInboxTypes.includes(props.messageType)) {
      return MESSAGE_VARIANTS.EMAIL;
    }
  }

  if (props.contentType === CONTENT_TYPES.INCOMING_EMAIL) {
    return MESSAGE_VARIANTS.EMAIL;
  }

  if (props.status === MESSAGE_STATUS.FAILED) return MESSAGE_VARIANTS.ERROR;
  if (props.contentAttributes?.isUnsupported)
    return MESSAGE_VARIANTS.UNSUPPORTED;

  if (props.contentAttributes?.externalEcho) {
    return MESSAGE_VARIANTS.AGENT;
  }

  const isBot =
    props.sender?.type === SENDER_TYPES.AGENT_BOT ||
    props.senderType === SENDER_TYPES.AGENT_BOT ||
    (!props.sender && !props.additionalAttributes?.senderName);
  if (isBot && props.messageType === MESSAGE_TYPES.OUTGOING) {
    return MESSAGE_VARIANTS.BOT;
  }

  const variants = {
    [MESSAGE_TYPES.INCOMING]: MESSAGE_VARIANTS.USER,
    [MESSAGE_TYPES.ACTIVITY]: MESSAGE_VARIANTS.ACTIVITY,
    [MESSAGE_TYPES.OUTGOING]: MESSAGE_VARIANTS.AGENT,
    [MESSAGE_TYPES.TEMPLATE]: MESSAGE_VARIANTS.TEMPLATE,
  };

  return variants[props.messageType] || MESSAGE_VARIANTS.USER;
});

const isBotOrAgentMessage = computed(() => {
  if (props.messageType === MESSAGE_TYPES.ACTIVITY) {
    return false;
  }
  // if an outgoing message is still processing, then it's definitely a
  // message sent by the current user
  if (
    props.status === MESSAGE_STATUS.PROGRESS &&
    props.messageType === MESSAGE_TYPES.OUTGOING
  ) {
    return true;
  }
  const senderId = props.senderId ?? props.sender?.id;
  const senderType = props.sender?.type ?? props.senderType;

  if (!senderType || !senderId) {
    return true;
  }

  if (
    [SENDER_TYPES.AGENT_BOT, SENDER_TYPES.CAPTAIN_ASSISTANT].includes(
      senderType
    )
  ) {
    return true;
  }

  return senderType.toLowerCase() === SENDER_TYPES.USER.toLowerCase();
});

/**
 * Computes the message orientation based on sender type and message type
 * @returns {import('vue').ComputedRef<'left'|'right'|'center'>} The computed orientation
 */
const orientation = computed(() => {
  if (isBotOrAgentMessage.value) {
    return ORIENTATION.RIGHT;
  }

  if (props.messageType === MESSAGE_TYPES.ACTIVITY) return ORIENTATION.CENTER;

  return ORIENTATION.LEFT;
});

const flexOrientationClass = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: 'justify-start',
    [ORIENTATION.RIGHT]: 'justify-end',
    [ORIENTATION.CENTER]: 'justify-center',
  };

  return map[orientation.value];
});

const isGroupIncoming = computed(() => {
  return (
    props.isGroupConversation && props.messageType === MESSAGE_TYPES.INCOMING
  );
});

const showGroupSenderAvatar = computed(() => {
  return isGroupIncoming.value && !props.groupWithPrevious;
});

const gridClass = computed(() => {
  if (orientation.value === ORIENTATION.LEFT && isGroupIncoming.value) {
    return 'grid grid-cols-[24px_1fr]';
  }

  const map = {
    [ORIENTATION.LEFT]: 'grid grid-cols-1fr',
    [ORIENTATION.RIGHT]: 'grid grid-cols-[1fr_24px]',
  };

  return map[orientation.value];
});

const gridTemplate = computed(() => {
  if (orientation.value === ORIENTATION.LEFT && isGroupIncoming.value) {
    return `
      "avatar bubble"
      "spacer meta"
    `;
  }

  const map = {
    [ORIENTATION.LEFT]: `
      "bubble"
      "meta"
    `,
    [ORIENTATION.RIGHT]: `
      "bubble avatar"
      "meta spacer"
    `,
  };

  return map[orientation.value];
});

const shouldGroupWithNext = computed(() => {
  if (props.status === MESSAGE_STATUS.FAILED) return false;

  return props.groupWithNext;
});

const shouldShowAvatar = computed(() => {
  if (props.messageType === MESSAGE_TYPES.ACTIVITY) return false;
  if (orientation.value === ORIENTATION.LEFT) return false;

  return true;
});

const componentToRender = computed(() => {
  if (props.isEmailInbox && !props.private) {
    const emailInboxTypes = [MESSAGE_TYPES.INCOMING, MESSAGE_TYPES.OUTGOING];
    if (emailInboxTypes.includes(props.messageType)) return EmailBubble;
  }

  if (props.contentAttributes?.whatsappFlowResponse) {
    return WhatsappFlowResponseBubble;
  }

  if (props.contentType === CONTENT_TYPES.INPUT_CSAT) {
    return CSATBubble;
  }

  if (
    [CONTENT_TYPES.INPUT_SELECT, CONTENT_TYPES.FORM].includes(props.contentType)
  ) {
    return FormBubble;
  }

  if (props.contentType === CONTENT_TYPES.VOICE_CALL) {
    return VoiceCallBubble;
  }

  if (props.contentType === CONTENT_TYPES.INCOMING_EMAIL) {
    return EmailBubble;
  }

  if (props.contentAttributes?.isUnsupported) {
    return UnsupportedBubble;
  }

  if (props.contentAttributes.type === 'dyte') {
    return DyteBubble;
  }

  const instagramSharedTypes = [
    ATTACHMENT_TYPES.STORY_MENTION,
    ATTACHMENT_TYPES.IG_STORY,
    ATTACHMENT_TYPES.IG_STORY_REPLY,
    ATTACHMENT_TYPES.IG_POST,
  ];
  if (instagramSharedTypes.includes(props.contentAttributes.imageType)) {
    return InstagramStoryBubble;
  }

  if (Array.isArray(props.attachments) && props.attachments.length === 1) {
    const fileType = props.attachments[0].fileType;

    if (fileType === ATTACHMENT_TYPES.FALLBACK) return FallbackBubble;

    if (!props.content) {
      if (fileType === ATTACHMENT_TYPES.IMAGE) return ImageBubble;
      if (fileType === ATTACHMENT_TYPES.FILE) return FileBubble;
      if (fileType === ATTACHMENT_TYPES.AUDIO) return AudioBubble;
      if (fileType === ATTACHMENT_TYPES.VIDEO) {
        return props.attachments[0].isVideoNote ? VideoNoteBubble : VideoBubble;
      }
      if (fileType === ATTACHMENT_TYPES.IG_REEL) return VideoBubble;
      if (fileType === ATTACHMENT_TYPES.EMBED) return EmbedBubble;
      if (fileType === ATTACHMENT_TYPES.LOCATION) return LocationBubble;
    }
    // Attachment content is the name of the contact
    if (fileType === ATTACHMENT_TYPES.CONTACT) return ContactBubble;
  }

  if (props.contentAttributes?.rich) {
    return RichMessageBubble;
  }

  return TextBubble;
});

const isAudioBubble = computed(() => componentToRender.value === AudioBubble);

const shouldShowContextMenu = computed(() => {
  return !props.contentAttributes?.isUnsupported;
});

const isBubble = computed(() => {
  return props.messageType !== MESSAGE_TYPES.ACTIVITY;
});

const isMessageDeleted = computed(() => {
  return props.contentAttributes?.deleted;
});

const isForwardedEmail = computed(
  () => !!props.contentAttributes?.forwardedMessageId && !isMessageDeleted.value
);

const shouldShowWhatsappReferral = computed(
  () =>
    variant.value === MESSAGE_VARIANTS.USER &&
    !!props.contentAttributes?.referral
);

const payloadForContextMenu = computed(() => {
  return {
    id: props.id,
    content_attributes: props.contentAttributes,
    content: displayedContent.value,
    conversation_id: props.conversationId,
  };
});

const contextMenuEnabledOptions = computed(() => {
  const hasText = !!props.content;
  const hasAttachments = !!(props.attachments && props.attachments.length > 0);
  const hasRichContent = !!props.contentAttributes?.rich;

  const isOutgoing = props.messageType === MESSAGE_TYPES.OUTGOING;
  const isFailedOrProcessing =
    props.status === MESSAGE_STATUS.FAILED ||
    props.status === MESSAGE_STATUS.PROGRESS;

  return {
    copy: hasText,
    delete:
      canDeleteMessage.value &&
      (hasText || hasAttachments || hasRichContent) &&
      !isFailedOrProcessing &&
      !isMessageDeleted.value,
    cannedResponse: isOutgoing && hasText && !isMessageDeleted.value,
    copyLink: !isFailedOrProcessing,
    translate:
      !isFailedOrProcessing &&
      !isMessageDeleted.value &&
      hasText &&
      !isAutoTranslated.value,
    replyTo:
      (props.private || props.inboxSupportsReplyTo.outgoing) &&
      !isFailedOrProcessing,
    edit:
      isOutgoing &&
      hasText &&
      !isFailedOrProcessing &&
      !isMessageDeleted.value &&
      props.inboxSupportsEdit,
    forwardEmail:
      props.isEmailInbox &&
      !props.private &&
      !isFailedOrProcessing &&
      !isMessageDeleted.value,
    report:
      isOnChatwootCloud.value &&
      isCaptainMessage.value &&
      !isMessageDeleted.value,
  };
});

const canShowReactionToolbar = computed(() => {
  if (!isBubble.value) return false;
  if (isMessageDeleted.value) return false;
  if (props.contentAttributes?.isUnsupported) return false;
  if (props.status === MESSAGE_STATUS.FAILED) return false;
  if (props.status === MESSAGE_STATUS.PROGRESS) return false;
  if (props.messageType === MESSAGE_TYPES.TEMPLATE) return false;
  // Private notes are agent-only and never leave Chatwoot, so reactions on
  // them don't depend on inbox channel capabilities or a provider source_id.
  if (props.private) return true;
  if (!props.inboxSupportsReactions) return false;
  // Mirror ReactionsController#target_unreactable_error: a non-private message
  // without a provider source_id can't be reacted to on WhatsApp, so the API
  // would 422 if the user clicked. Hide the picker instead of a dead action.
  if (!props.sourceId) return false;
  return true;
});

// Short cooldown after a click so a quick double-tap (or open-pick-reopen-pick
// on the picker) doesn't fire two POSTs against the same emoji. Watching
// reactions is not enough — the optimistic add mutates them synchronously, so
// we'd unblock before the human could react.
const REACTION_COOLDOWN_MS = 500;
const pendingEmojis = ref(new Set());

const currentUserReactionEmoji = computed(() => {
  const own = props.reactions.find(
    r =>
      (r.senderType === 'user' && r.senderId === props.currentUserId) ||
      (r.messageType === 1 && r.senderId == null)
  );
  return own?.emoji ?? null;
});

// Track pending cooldown timers so we can clear them on unmount and avoid
// touching `pendingEmojis` after the component is gone.
const pendingTimeouts = new Set();

function handleToggleReaction(emoji) {
  if (pendingEmojis.value.has(emoji)) return;
  pendingEmojis.value = new Set([...pendingEmojis.value, emoji]);
  emit('toggleReaction', {
    messageId: props.id,
    targetSourceId: props.sourceId,
    emoji,
  });
  const timeoutId = setTimeout(() => {
    pendingTimeouts.delete(timeoutId);
    if (!pendingEmojis.value.has(emoji)) return;
    const next = new Set(pendingEmojis.value);
    next.delete(emoji);
    pendingEmojis.value = next;
  }, REACTION_COOLDOWN_MS);
  pendingTimeouts.add(timeoutId);
}

onUnmounted(() => {
  pendingTimeouts.forEach(clearTimeout);
  pendingTimeouts.clear();
});

const shouldRenderMessage = computed(() => {
  const hasAttachments = !!(props.attachments && props.attachments.length > 0);
  const isEmailContentType = props.contentType === CONTENT_TYPES.INCOMING_EMAIL;
  const isUnsupported = props.contentAttributes?.isUnsupported;
  const isAnIntegrationMessage =
    props.contentType === CONTENT_TYPES.INTEGRATIONS;
  const hasWhatsappFlowResponse =
    !!props.contentAttributes?.whatsappFlowResponse;
  const isFailedMessage = props.status === MESSAGE_STATUS.FAILED;
  const hasExternalError = !!props.contentAttributes?.externalError;
  const hasRichContent = !!props.contentAttributes?.rich;

  return (
    hasAttachments ||
    props.content ||
    isEmailContentType ||
    isUnsupported ||
    isAnIntegrationMessage ||
    hasWhatsappFlowResponse ||
    shouldShowWhatsappReferral.value ||
    isFailedMessage ||
    hasExternalError ||
    hasRichContent
  );
});

function openContextMenu(e) {
  const shouldSkipContextMenu =
    e.target?.classList.contains('skip-context-menu') ||
    ['a', 'img'].includes(e.target?.tagName.toLowerCase());
  if (shouldSkipContextMenu || getSelection().toString()) {
    return;
  }

  e.preventDefault();
  if (e.type === 'contextmenu') {
    useTrack(ACCOUNT_EVENTS.OPEN_MESSAGE_CONTEXT_MENU);
  }
  contextMenuPosition.value = {
    x: e.pageX || e.clientX,
    y: e.pageY || e.clientY,
  };
  showContextMenu.value = true;
}

function closeContextMenu() {
  showContextMenu.value = false;
  contextMenuPosition.value = { x: null, y: null };
}

function openForwardEmail() {
  forwardEmailPosition.value = { ...contextMenuPosition.value };
  showForwardEmail.value = true;
}

function handleReplyTo() {
  const replyStorageKey = LOCAL_STORAGE_KEYS.MESSAGE_REPLY_TO;
  const { conversationId, id: replyTo } = props;

  LocalStorage.updateJsonStore(replyStorageKey, conversationId, replyTo);
  emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, props);
}

const avatarInfo = computed(() => {
  if (props.contentAttributes?.externalEcho) {
    const { name, avatar_url, channel_type, medium, voice_enabled } =
      inbox.value;
    const iconName = avatar_url
      ? null
      : getInboxIconByType(channel_type, medium, 'fill', voice_enabled);
    return {
      name: iconName ? '' : name || t('CONVERSATION.NATIVE_APP'),
      src: avatar_url || '',
      iconName,
    };
  }

  // If no sender, check for external sender name or integration sender info
  if (!props.sender) {
    const externalSenderName = props.contentAttributes?.externalSenderName;
    if (externalSenderName === 'WhatsApp') {
      return {
        name: t('CONVERSATION.WHATSAPP'),
        src: '',
        iconName: 'i-woot-whatsapp',
      };
    }
    const { senderName, senderAvatarUrl } = props.additionalAttributes || {};
    if (senderName) {
      return { name: senderName, src: senderAvatarUrl ?? '' };
    }
    return { name: t('CONVERSATION.BOT'), src: '' };
  }

  const { sender } = props;
  const { name, type, avatarUrl, thumbnail } = sender || {};

  // If sender type is agent bot, use avatarUrl
  if ([SENDER_TYPES.AGENT_BOT, SENDER_TYPES.CAPTAIN_ASSISTANT].includes(type)) {
    return {
      name: name ?? '',
      src: avatarUrl ?? '',
    };
  }

  // For all other senders, use thumbnail
  return {
    name: name ?? '',
    src: thumbnail ?? '',
  };
});

const avatarTooltip = computed(() => {
  if (props.contentAttributes?.externalEcho) {
    return replaceInstallationName(t('CONVERSATION.NATIVE_APP_ADVISORY'));
  }
  if (avatarInfo.value.name === '') return '';
  return `${t('CONVERSATION.SENT_BY')} ${avatarInfo.value.name}`;
});

// Colors for group sender names, matching AVATAR_COLORS from Avatar component
const SENDER_NAME_COLORS = {
  light: ['#C2298A', '#99543A', '#60646C', '#008573', '#4747C2', '#3A5BC7'],
  dark: ['#FF8DCC', '#FFA366', '#ADB1B8', '#0BD8B6', '#A19EFF', '#9EB1FF'],
};

const showGroupSenderName = computed(() => {
  return (
    props.isGroupConversation &&
    props.messageType === MESSAGE_TYPES.INCOMING &&
    !props.groupWithPrevious &&
    props.sender?.name
  );
});

const senderNameStyle = computed(() => {
  if (!showGroupSenderName.value) return {};
  const name = props.sender?.name || '';
  const index = name.length % SENDER_NAME_COLORS.light.length;
  return {
    color: SENDER_NAME_COLORS.light[index],
    '--dark-sender-color': SENDER_NAME_COLORS.dark[index],
  };
});

const navigateToGroupSender = event => {
  if (
    !isGroupIncoming.value ||
    !props.sender?.id ||
    props.sender.type?.toLowerCase() !== 'contact'
  )
    return;
  const accountId = route.params.accountId;
  const url = `/app/accounts/${accountId}/contacts/${props.sender.id}`;
  if (event?.ctrlKey || event?.metaKey) {
    window.open(url, '_blank');
  } else {
    router.push(url);
  }
};

const setupHighlightTimer = () => {
  if (Number(route.query.messageId) !== Number(props.id)) {
    return;
  }

  showBackgroundHighlight.value = true;
  const HIGHLIGHT_TIMER = 1000;
  useTimeoutFn(() => {
    showBackgroundHighlight.value = false;
  }, HIGHLIGHT_TIMER);
};

const HIGHLIGHT_DURATION = 1000;
const onHighlightMessage = ({ messageId } = {}) => {
  if (Number(messageId) !== Number(props.id)) return;
  showBackgroundHighlight.value = true;
  useTimeoutFn(() => {
    showBackgroundHighlight.value = false;
  }, HIGHLIGHT_DURATION);
};

onMounted(() => {
  setupHighlightTimer();
  emitter.on(BUS_EVENTS.HIGHLIGHT_MESSAGE, onHighlightMessage);
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.HIGHLIGHT_MESSAGE, onHighlightMessage);
});

provideMessageContext({
  ...toRefs(props),
  showingOriginal,
  contactSide,
  isCaptainMessage,
  isPrivate: computed(() => props.private),
  variant,
  orientation,
  isBotOrAgentMessage,
  shouldGroupWithNext,
});
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <div
    v-if="shouldRenderMessage"
    :id="`message${props.id}`"
    class="flex w-full mb-2 message-bubble-container group"
    :data-message-id="props.id"
    :class="[
      flexOrientationClass,
      {
        'group-with-next': shouldGroupWithNext,
        'bg-n-alpha-1': showBackgroundHighlight,
      },
    ]"
  >
    <div v-if="variant === MESSAGE_VARIANTS.ACTIVITY">
      <ActivityBubble :content="content" />
    </div>
    <div
      v-else
      :class="[
        gridClass,
        {
          'gap-y-2': contentAttributes.externalError,
          'w-full': variant === MESSAGE_VARIANTS.EMAIL,
        },
      ]"
      class="gap-x-2"
      :style="{
        gridTemplateAreas: gridTemplate,
      }"
    >
      <div
        v-if="showGroupSenderAvatar"
        class="[grid-area:avatar] flex items-end"
      >
        <Avatar
          v-tooltip.right-end="avatarTooltip"
          v-bind="avatarInfo"
          :size="24"
          class="cursor-pointer"
          @click="navigateToGroupSender($event)"
        />
      </div>
      <div
        v-if="!shouldGroupWithNext && shouldShowAvatar"
        v-tooltip.left-end="avatarTooltip"
        class="[grid-area:avatar] flex items-end"
      >
        <Avatar v-bind="avatarInfo" :size="24" />
      </div>
      <div class="[grid-area:bubble]" @contextmenu="openContextMenu($event)">
        <span
          v-if="showGroupSenderName"
          class="text-xs font-medium mb-0.5 inline-block ltr:mr-8 rtl:ml-8 cursor-pointer hover:underline dark:!text-[var(--dark-sender-color)]"
          :style="senderNameStyle"
          @click="navigateToGroupSender($event)"
        >
          {{ sender?.name }}
        </span>
        <div
          v-if="isForwardedEmail"
          class="flex min-w-0 mb-2"
          :class="{
            'ltr:ml-8 rtl:mr-8 justify-end': orientation === ORIENTATION.RIGHT,
            'ltr:mr-8 rtl:ml-8': orientation === ORIENTATION.LEFT,
          }"
        >
          <ForwardedEmailBanner />
        </div>
        <div
          class="flex min-w-0"
          :class="{
            'ltr:ml-8 rtl:mr-8 justify-end': orientation === ORIENTATION.RIGHT,
            'ltr:mr-8 rtl:ml-8': orientation === ORIENTATION.LEFT,
          }"
        >
          <div class="relative">
            <Component :is="componentToRender" />
            <div
              v-if="canShowReactionToolbar"
              class="absolute top-1/2 -translate-y-1/2 z-10 flex items-center gap-0.5 rounded-full border border-n-slate-6 bg-n-solid-2 shadow-sm p-0.5 transition-opacity [@media(hover:none)]:opacity-100"
              :class="[
                reactionPickerOpen
                  ? 'opacity-100'
                  : 'opacity-0 group-hover:opacity-100 group-focus-within:opacity-100',
                orientation === ORIENTATION.RIGHT
                  ? 'ltr:right-full ltr:mr-2 rtl:left-full rtl:ml-2'
                  : 'ltr:left-full ltr:ml-2 rtl:right-full rtl:mr-2',
              ]"
            >
              <EmojiReactionPicker
                :alignment="
                  orientation === ORIENTATION.RIGHT ? 'right' : 'left'
                "
                :current-user-emoji="currentUserReactionEmoji"
                @select="handleToggleReaction"
                @update:open="value => (reactionPickerOpen = value)"
              />
            </div>
          </div>
        </div>
        <div
          v-if="reactions.length > 0"
          class="flex"
          :class="{
            'ltr:ml-8 rtl:mr-8 justify-end': orientation === ORIENTATION.RIGHT,
            'ltr:mr-8 rtl:ml-8': orientation === ORIENTATION.LEFT,
          }"
        >
          <ReactionDisplay
            :reactions="reactions"
            :current-user-id="currentUserId"
            :pending-emojis="pendingEmojis"
            :alignment="orientation === ORIENTATION.RIGHT ? 'right' : 'left'"
            :read-only="!inboxSupportsReactions && !props.private"
            :overlap="!isAudioBubble"
            @toggle="handleToggleReaction"
          />
        </div>
      </div>
      <MessageError
        v-if="contentAttributes.externalError"
        class="[grid-area:meta]"
        :class="flexOrientationClass"
        :error="contentAttributes.externalError"
        @retry="emit('retry')"
      />
    </div>
    <div v-if="shouldShowContextMenu" class="context-menu-wrap">
      <ContextMenu
        v-if="isBubble"
        :context-menu-position="contextMenuPosition"
        :is-open="showContextMenu"
        :enabled-options="contextMenuEnabledOptions"
        :message="payloadForContextMenu"
        hide-button
        @open="openContextMenu"
        @close="closeContextMenu"
        @reply-to="handleReplyTo"
        @forward-email="openForwardEmail"
      />
      <ForwardEmailPanel
        v-if="showForwardEmail"
        :x="forwardEmailPosition.x"
        :y="forwardEmailPosition.y"
        @close="showForwardEmail = false"
      />
    </div>
  </div>
</template>

<style lang="scss">
.group-with-next + .message-bubble-container {
  .left-bubble {
    @apply ltr:rounded-tl-sm rtl:rounded-tr-sm;
  }

  .right-bubble {
    @apply ltr:rounded-tr-sm rtl:rounded-tl-sm;
  }
}
</style>
