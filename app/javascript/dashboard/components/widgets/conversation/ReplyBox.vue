<script>
import { defineAsyncComponent, getCurrentInstance, useTemplateRef } from 'vue';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useInboxSignatures } from 'dashboard/composables/useInboxSignatures';
import { useTrack } from 'dashboard/composables';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';

import ReplyToMessage from './ReplyToMessage.vue';
import AttachmentPreview from 'dashboard/components/widgets/AttachmentsPreview.vue';
import ReplyTopPanel from 'dashboard/components/widgets/WootWriter/ReplyTopPanel.vue';
import ReplyEmailHead from './ReplyEmailHead.vue';
import ReplyBottomPanel from 'dashboard/components/widgets/WootWriter/ReplyBottomPanel.vue';
import CopilotReplyBottomPanel from 'dashboard/components/widgets/WootWriter/CopilotReplyBottomPanel.vue';
import ArticleSearchPopover from 'dashboard/routes/dashboard/helpcenter/components/ArticleSearch/SearchPopover.vue';
import CopilotEditorSection from './CopilotEditorSection.vue';
import MessageSignatureMissingAlert from './MessageSignatureMissingAlert.vue';
import ReplyBoxBanner from './ReplyBoxBanner.vue';
import QuotedEmailPreview from './QuotedEmailPreview.vue';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';

// How many mode switches a capture may still be uploading across before the composer stops
// holding an explanation for it. Nothing survives five, and the cap is what keeps a marker
// nobody claims from sitting in a component that stays mounted all day.
const MAX_PENDING_DISCARD_MARKERS = 5;
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import AudioRecorder from 'dashboard/components/widgets/WootWriter/AudioRecorder.vue';
import { AUDIO_FORMATS } from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { CMD_AI_ASSIST } from 'dashboard/helper/commandbar/events';
import { usableFilesFromTransfer } from 'dashboard/helper/pastedFiles';
import {
  getUndefinedVariablesInMessage,
  replaceVariablesInMessage,
} from '@chatwoot/utils';
import WhatsappTemplates from './WhatsappTemplates/Modal.vue';
import ContentTemplates from './ContentTemplates/ContentTemplatesModal.vue';
import ScheduledMessageModal from 'dashboard/routes/dashboard/conversation/scheduledMessages/ScheduledMessageModal.vue';
import { MESSAGE_MAX_LENGTH } from 'shared/helpers/MessageTypeHelper';
import { isComposing } from 'shared/helpers/KeyboardHelpers';
import inboxMixin, { INBOX_FEATURES } from 'shared/mixins/inboxMixin';
import { CAPABILITIES } from 'dashboard/helper/whatsappSession';
import { trimContent, debounce, getRecipients } from '@chatwoot/utils';
import wootConstants from 'dashboard/constants/globals';
import {
  extractQuotedEmailText,
  buildQuotedEmailHeader,
  appendQuotedTextToMessage,
} from 'dashboard/helper/quotedEmailHelper';
import {
  CONVERSATION_EVENTS,
  CAPTAIN_EVENTS,
} from '../../../helper/AnalyticsHelper/events';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import {
  appendSignature,
  getEffectiveChannelType,
  getReplyVariables,
  stripUnsupportedMarkdown,
} from 'dashboard/helper/editorHelper';
import { useCopilotReply } from 'dashboard/composables/useCopilotReply';
import { useMacroExecution } from 'dashboard/composables/useMacroExecution';
import ConversationResolveAttributesModal from 'dashboard/components-next/ConversationWorkflow/ConversationResolveAttributesModal.vue';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { isFileTypeAllowedForChannel } from 'shared/helpers/FileHelper';
import { isInboxAdminInGroup } from 'dashboard/helper/phoneHelper';
import { isAIAssigneeType } from 'dashboard/helper/agentHelper';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import { CONTENT_TYPES } from 'dashboard/components-next/message/constants';

import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { LocalStorage } from 'shared/helpers/localStorage';
import { emitter } from 'shared/helpers/mitt';
const EmojiIconPicker = defineAsyncComponent(
  () =>
    import('dashboard/components-next/emoji-icon-picker/EmojiIconPicker.vue')
);

export default {
  components: {
    ArticleSearchPopover,
    AttachmentPreview,
    AudioRecorder,
    ReplyBoxBanner,
    EmojiIconPicker,
    MessageSignatureMissingAlert,
    ReplyBottomPanel,
    ReplyEmailHead,
    ReplyToMessage,
    ReplyTopPanel,
    ContentTemplates,
    WhatsappTemplates,
    WootMessageEditor,
    QuotedEmailPreview,
    CopilotEditorSection,
    CopilotReplyBottomPanel,
    ScheduledMessageModal,
    ConversationResolveAttributesModal,
  },
  mixins: [inboxMixin, fileUploadMixin],
  emits: ['toggleEditorSize'],
  setup() {
    const {
      uiSettings,
      isEditorHotKeyEnabled,
      fetchSignatureFlagFromUISettings,
    } = useUISettings();

    const {
      fetchInboxSignatures,
      getSignatureForInbox,
      getSignatureSettingsForInbox,
    } = useInboxSignatures();

    fetchInboxSignatures();

    const { formatMessage } = useMessageFormatter();

    const messageEditor = useTemplateRef('messageEditor');
    const copilot = useCopilotReply();
    const macroExecution = useMacroExecution();
    const shortcutKey = useKbd(['$mod', '+', 'enter']);

    // Options API state and methods live on the instance proxy
    const { proxy } = getCurrentInstance();
    useKeyboardEvents({
      Escape: {
        action: () => proxy.hideEmojiPicker(),
        allowOnFocusedInput: true,
      },
      '$mod+KeyK': {
        action: e => {
          e.preventDefault();
          // ninja-keys skips its own hotkey inside the editor; the v2 bar binds its own.
          document.querySelector('ninja-keys')?.open();
        },
        allowOnFocusedInput: true,
      },
      Enter: {
        action: e => {
          if (isComposing(e)) return;
          if (proxy.isAValidEvent('enter')) {
            proxy.onSendReply();
            e.preventDefault();
          }
        },
        allowOnFocusedInput: true,
      },
      '$mod+Enter': {
        action: e => {
          if (isComposing(e)) return;
          if (copilot.isActive.value && proxy.isFocused) {
            proxy.onSubmitCopilotReply();
          } else if (proxy.isAValidEvent('cmd_enter')) {
            proxy.onSendReply();
          }
        },
        allowOnFocusedInput: true,
      },
      '$mod+KeyZ': {
        action: e => {
          // The editor prevents default only when its own history undid a
          // step; inputs keep their native undo. Shift means redo.
          if (e.defaultPrevented || e.shiftKey) return;
          if (['INPUT', 'TEXTAREA'].includes(e.target?.tagName)) return;
          // Only act inside the composer, or with nothing focused (right
          // after clicking remove); never hijack another editor's undo.
          const inComposer =
            e.target instanceof Element && !!e.target.closest('.reply-box');
          if (!inComposer && e.target !== document.body) return;
          if (proxy.restoreQuotedEmail()) e.preventDefault();
        },
        allowOnFocusedInput: true,
      },
    });

    return {
      uiSettings,
      isEditorHotKeyEnabled,
      fetchSignatureFlagFromUISettings,
      getSignatureForInbox,
      getSignatureSettingsForInbox,
      messageEditor,
      copilot,
      shortcutKey,
      formatMessage,
      macroExecution,
    };
  },
  data() {
    return {
      message: '',
      inReplyTo: {},
      isFocused: false,
      showEmojiPicker: false,
      attachedFiles: [],
      // Bumped whenever the composer's privacy or conversation changes. A capture
      // stamps it on the way in, so an upload that lands afterwards can tell that
      // it outlived what the agent was composing under.
      composerGeneration: 0,
      // The generations ended by a mode change that nobody has been told about yet. A
      // capture carries the generation it was staged under, so the answer it is owed is a
      // fact about that generation and not about the latest one -- one slot cannot hold two
      // outstanding captures, and cannot tell an unanswered marker from a stale one.
      //
      // Bounded, because ReplyBox stays mounted for the whole session and an entry nothing
      // ever claims would otherwise sit here for good: past a handful of mode switches a
      // capture is not still uploading.
      composerDropGenerations: [],
      // The recorder's capture starts when the mic is armed, not when the file
      // shows up: talking and then converting to MP3 both happen in between.
      recordingGeneration: 0,
      isRecordingAudio: false,
      recordingAudioState: '',
      recordingAudioDurationText: '',
      replyType: REPLY_EDITOR_MODES.REPLY,
      draftConversationId: null,
      draftReplyMode: null,
      bccEmails: '',
      ccEmails: '',
      toEmails: '',
      subject: '',
      doAutoSaveDraft: () => {},
      showWhatsAppTemplatesModal: false,
      requestContactInfoTemplatesOnly: false,
      showContentTemplatesModal: false,
      updateEditorSelectionWith: '',
      undefinedVariableMessage: '',
      showMentions: false,
      showUserMentions: false,
      showCannedMenu: false,
      showVariablesMenu: false,
      showMacrosMenu: false,
      newConversationModalActive: false,
      showArticleSearchPopover: false,
      showScheduledMessageModal: false,
      copilotAcceptedMessages: {},
      isQuoteRemoved: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      currentUser: 'getCurrentUser',
      lastEmail: 'getLastEmailInSelectedChat',
      globalConfig: 'globalConfig/get',
      isMetaMessageSendingDisabled: 'globalConfig/isMetaMessageSendingDisabled',
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    isMacrosEnabled() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.MACROS
      );
    },
    currentContact() {
      const senderId = this.currentChat?.meta?.sender?.id;
      if (!senderId) return {};
      return this.$store.getters['contacts/getContact'](senderId);
    },
    isGroupConversation() {
      return this.currentChat?.group_type === 'group';
    },
    // The inbox is part of the target, not only the contact. A group contact is
    // account-scoped, so the same group can be open in two inboxes of one account, and
    // what the panel may do there is answered per inbox. Keyed on the contact alone,
    // switching between the two threads kept the first inbox's answer.
    groupMembersFetchTarget() {
      if (!this.groupContactId || !this.isGroupConversation) return null;
      // `groups` and not `group_management`: this fetch reads the GroupMember rows the
      // inbound path already filed, through Chatwoot's own API, and never reaches the
      // provider. Asking for the command surface here would leave a receive-only inbox
      // without `is_inbox_admin`, and an announcement-only group would look replyable
      // until the server refused the message.
      if (!this.hasInboxCapability(CAPABILITIES.GROUPS)) return null;

      return `${this.groupContactId}:${this.currentChat?.inbox_id}`;
    },
    groupContactId() {
      return this.currentChat?.meta?.sender?.id || null;
    },
    inboxPhoneNumber() {
      return this.inbox?.phone_number || null;
    },
    groupMembers() {
      if (!this.groupContactId) return [];
      return (
        this.$store.getters['groupMembers/getGroupMembers'](
          this.groupContactId
        ) || []
      );
    },
    groupMembersMeta() {
      if (!this.groupContactId) return {};
      return (
        this.$store.getters['groupMembers/getGroupMembersMeta'](
          this.groupContactId,
          this.currentChat?.inbox_id
        ) || {}
      );
    },
    isInboxAdminInCurrentGroup() {
      const meta = this.groupMembersMeta;
      if (meta.is_inbox_admin != null) return meta.is_inbox_admin;
      const inboxPhone = meta.inbox_phone_number || this.inboxPhoneNumber;
      return isInboxAdminInGroup(inboxPhone, this.groupMembers);
    },
    isGroupMembersLoaded() {
      const meta = this.groupMembersMeta;
      return meta.is_inbox_admin != null || this.groupMembers.length > 0;
    },
    isAnnouncementModeRestricted() {
      return (
        this.isASessionWhatsAppChannel &&
        this.isGroupConversation &&
        this.currentContact?.additional_attributes?.announce === true &&
        this.isGroupMembersLoaded &&
        !this.isInboxAdminInCurrentGroup
      );
    },
    // Read off the conversation, not off the contact: a group contact is
    // account-scoped and the same group can be open in two inboxes of one account,
    // where only one of them may have left. The server answers for this thread's own
    // number.
    isGroupLeft() {
      return (
        this.isASessionWhatsAppChannel &&
        this.isGroupConversation &&
        this.currentChat?.group_left === true
      );
    },
    isGroupsDisabled() {
      // The server already strips the group capabilities when the kill switch is off, so
      // the absence of `groups` is what "disabled" means here — for every provider.
      return (
        this.isASessionWhatsAppChannel &&
        this.isGroupConversation &&
        !this.hasInboxCapability(CAPABILITIES.GROUPS)
      );
    },
    shouldShowReplyToMessage() {
      if (!this.inReplyTo?.id) return false;
      if (this.copilot.isActive.value) return false;
      // Private notes are agent-only and don't depend on an external channel
      // for reply propagation, so the channel feature gates don't apply.
      if (this.isPrivate) return true;
      return (
        this.inboxHasFeature(INBOX_FEATURES.REPLY_TO) &&
        !this.is360DialogWhatsAppChannel
      );
    },
    showWhatsappTemplates() {
      // We support templates for API channels if someone updates templates manually via API
      // That's why we don't explicitly check for channel type here
      const templates = this.$store.getters['inboxes/getWhatsAppTemplates'](
        this.inboxId
      );
      return !!(templates && templates.length) && !this.isPrivate;
    },
    showContentTemplates() {
      return this.isATwilioWhatsAppChannel && !this.isPrivate;
    },
    isWithinMessagingWindow() {
      return !!(
        this.currentChat?.can_reply ||
        this.isAWhatsAppChannel ||
        this.isAPIInbox
      );
    },
    canSendPublicReply() {
      return (
        this.isWithinMessagingWindow &&
        !this.isAIOwnedPendingConversation &&
        !this.isInstagramReplyRestricted
      );
    },
    isVoiceCallConversation() {
      if (!this.currentChat.messages) return false;
      return (
        getLastMessage(this.currentChat)?.content_type ===
        CONTENT_TYPES.VOICE_CALL
      );
    },
    isInstagramReplyRestricted() {
      return this.isMetaMessageSendingDisabled && this.isAnInstagramChannel;
    },
    isPrivate() {
      return (
        !this.canSendPublicReply || this.replyType === REPLY_EDITOR_MODES.NOTE
      );
    },
    isOnPrivateNote() {
      if (this.isInstagramReplyRestricted) {
        return true;
      }

      return this.isAIOwnedPendingConversation
        ? this.isPrivate
        : this.replyType === REPLY_EDITOR_MODES.NOTE;
    },
    effectiveReplyMode() {
      return this.isOnPrivateNote
        ? REPLY_EDITOR_MODES.NOTE
        : REPLY_EDITOR_MODES.REPLY;
    },
    hasMeaningfulEditorContent() {
      // Signatures are applied at send time (never injected into the editor),
      // so the raw body is enough to know whether the agent typed anything.
      return !!(this.message || '').trim();
    },
    isAIOwnedPendingConversation() {
      return (
        this.currentChat?.status === wootConstants.STATUS_TYPE.PENDING &&
        isAIAssigneeType(this.currentChat?.meta?.assignee_type)
      );
    },
    inboxId() {
      return this.currentChat.inbox_id;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },
    messagePlaceHolder() {
      if (this.isGroupsDisabled && !this.isOnPrivateNote) {
        return this.$t('CONVERSATION.FOOTER.GROUPS_DISABLED_RESTRICTED');
      }
      if (this.isGroupLeft && !this.isOnPrivateNote) {
        return this.$t('CONVERSATION.FOOTER.GROUP_LEFT_RESTRICTED');
      }
      if (this.isAnnouncementModeRestricted && !this.isOnPrivateNote) {
        return this.$t('CONVERSATION.FOOTER.ANNOUNCEMENT_MODE_RESTRICTED');
      }
      if (this.isEditorDisabled) {
        if (this.isAWhatsAppChannel) {
          return this.$t('CONVERSATION.FOOTER.MESSAGING_RESTRICTED_WHATSAPP');
        }
        if (this.isAPIInbox) {
          return this.$t('CONVERSATION.FOOTER.MESSAGING_RESTRICTED_API');
        }
        return this.$t('CONVERSATION.FOOTER.MESSAGING_RESTRICTED');
      }
      return this.isPrivate
        ? this.$t('CONVERSATION.FOOTER.PRIVATE_MSG_INPUT')
        : this.$t('CONVERSATION.FOOTER.MSG_INPUT');
    },
    isMessageLengthReachingThreshold() {
      return this.message.length > this.maxLength - 50;
    },
    charactersRemaining() {
      return this.maxLength - this.message.length;
    },
    isReplyButtonDisabled() {
      if (this.isEditorDisabled) return true;
      if (this.isATwitterInbox) return true;
      if (this.hasAttachments || this.hasRecordedAudio) return false;

      return (
        this.isMessageEmpty ||
        this.message.length === 0 ||
        this.message.length > this.maxLength
      );
    },
    sender() {
      return {
        name: this.currentUser.name,
        thumbnail: this.currentUser.avatar_url,
      };
    },
    conversationType() {
      const { additional_attributes: additionalAttributes } = this.currentChat;
      const type = additionalAttributes ? additionalAttributes.type : '';
      return type || '';
    },
    maxLength() {
      if (this.isPrivate) {
        return MESSAGE_MAX_LENGTH.GENERAL;
      }
      if (this.isAFacebookInbox) {
        return MESSAGE_MAX_LENGTH.FACEBOOK;
      }
      if (this.isAnInstagramChannel) {
        return MESSAGE_MAX_LENGTH.INSTAGRAM;
      }
      if (this.isATelegramChannel) {
        return MESSAGE_MAX_LENGTH.TELEGRAM;
      }
      if (this.isATiktokChannel) {
        return MESSAGE_MAX_LENGTH.TIKTOK;
      }
      if (this.isATwilioWhatsAppChannel) {
        return MESSAGE_MAX_LENGTH.TWILIO_WHATSAPP;
      }
      if (this.isAWhatsAppCloudChannel) {
        return MESSAGE_MAX_LENGTH.WHATSAPP_CLOUD;
      }
      if (this.isASmsInbox) {
        return MESSAGE_MAX_LENGTH.TWILIO_SMS;
      }
      if (this.isAnEmailChannel) {
        return MESSAGE_MAX_LENGTH.EMAIL;
      }
      if (this.isATwilioSMSChannel) {
        return MESSAGE_MAX_LENGTH.TWILIO_SMS;
      }
      if (this.isAWhatsAppChannel) {
        return MESSAGE_MAX_LENGTH.WHATSAPP_CLOUD;
      }
      return MESSAGE_MAX_LENGTH.GENERAL;
    },
    showFileUpload() {
      const { image_send: imageSend } =
        this.currentChat?.additional_attributes?.tiktok_capabilities ?? {};
      const tiktokAttachmentSupported = imageSend ?? true;

      return (
        this.isAWebWidgetInbox ||
        this.isAFacebookInbox ||
        this.isAWhatsAppChannel ||
        this.isAPIInbox ||
        this.isAnEmailChannel ||
        this.isASmsInbox ||
        this.isATelegramChannel ||
        this.isALineChannel ||
        this.isAnInstagramChannel ||
        (this.isATiktokChannel && tiktokAttachmentSupported)
      );
    },
    replyButtonLabel() {
      let sendMessageText = this.$t('CONVERSATION.REPLYBOX.SEND');
      if (this.isPrivate) {
        sendMessageText = this.$t('CONVERSATION.REPLYBOX.CREATE');
      }
      const keyLabel = this.isEditorHotKeyEnabled('cmd_enter')
        ? `(${this.shortcutKey})`
        : '(↵)';
      return `${sendMessageText} ${keyLabel}`;
    },
    replyBoxClass() {
      return {
        'is-private': this.isPrivate,
        'is-focused': this.isFocused || this.hasAttachments,
      };
    },
    hasAttachments() {
      return this.attachedFiles.length;
    },
    hasRecordedAudio() {
      return this.attachedFiles.some(file => file.isVoiceMessage);
    },
    showAudioRecorder() {
      // A private note never reaches the channel, so the channel's upload
      // support doesn't gate it — same rule the attach button already follows.
      return this.showFileUpload || this.isOnPrivateNote;
    },
    showAudioRecorderEditor() {
      return this.showAudioRecorder && this.isRecordingAudio;
    },
    isOnExpandedLayout() {
      const {
        LAYOUT_TYPES: { CONDENSED },
      } = wootConstants;
      const { conversation_display_type: conversationDisplayType = CONDENSED } =
        this.uiSettings;
      return conversationDisplayType !== CONDENSED;
    },
    isMessageEmpty() {
      if (!this.message) {
        return true;
      }
      return !this.message.trim().replace(/\n/g, '').length;
    },
    showReplyHead() {
      return !this.isOnPrivateNote && this.isAnEmailChannel;
    },
    enableMultipleFileUpload() {
      return (
        this.isAnEmailChannel ||
        this.isAWebWidgetInbox ||
        this.isAPIInbox ||
        this.isAWhatsAppChannel ||
        this.isATelegramChannel
      );
    },
    isSignatureEnabledForInbox() {
      return !this.isPrivate && this.sendWithSignature;
    },
    messageSignature() {
      return this.getSignatureForInbox(this.inboxId);
    },
    isSignatureAvailable() {
      return !!this.messageSignature;
    },
    sendWithSignature() {
      return this.fetchSignatureFlagFromUISettings(this.channelType);
    },
    conversationId() {
      return this.currentChat.id;
    },
    conversationIdByRoute() {
      return this.conversationId;
    },
    editorStateId() {
      return `draft-${this.conversationIdByRoute}-${this.effectiveReplyMode}`;
    },
    audioRecordFormat() {
      // Notes stay inside Chatwoot, so the channel's preferred container is
      // irrelevant. MP3 is the one format every browser and both mobile apps
      // play, and it keeps long notes under the 25 MB transcription ceiling
      // that uncompressed WAV would blow past in ~5 minutes.
      if (this.isOnPrivateNote) {
        return AUDIO_FORMATS.MP3;
      }
      // The native connector sends the file as it gets it and does not transcode,
      // and Android plays a voice note only as Opus in Ogg. OGG costs nothing here:
      // Chrome and Firefox record Opus in WebM and convertAudio only remuxes it.
      // The other session providers convert on their own side, so they keep MP3.
      if (
        this.isAWhatsAppCloudChannel ||
        (this.isAWhatsAppChannel && this.whatsAppAPIProvider === 'native')
      ) {
        return AUDIO_FORMATS.OGG;
      }
      if (this.isAWhatsAppChannel || this.isATelegramChannel) {
        return AUDIO_FORMATS.MP3;
      }
      if (this.isAPIInbox) {
        return AUDIO_FORMATS.MP3;
      }
      return AUDIO_FORMATS.WAV;
    },
    messageVariables() {
      return getReplyVariables({
        conversation: this.currentChat,
        contact: this.currentContact,
        inbox: this.inbox,
        user: this.currentUser,
      });
    },
    connectedPortalSlug() {
      const { help_center: portal = {} } = this.inbox;
      const { slug = '' } = portal;
      return slug;
    },
    lastEmailWithQuotedContent() {
      if (!this.isAnEmailChannel) {
        return null;
      }

      const lastEmail = this.lastEmail;
      if (!lastEmail || lastEmail.private) {
        return null;
      }

      return lastEmail;
    },
    quotedEmailText() {
      return extractQuotedEmailText(this.lastEmailWithQuotedContent);
    },
    quotedEmailHeader() {
      return buildQuotedEmailHeader(
        this.lastEmailWithQuotedContent,
        this.currentContact,
        this.inbox
      );
    },
    shouldIncludeQuotedEmail() {
      return (
        this.isAnEmailChannel &&
        !this.isOnPrivateNote &&
        !this.isQuoteRemoved &&
        !!this.quotedEmailText
      );
    },
    isDefaultEditorMode() {
      return !this.showAudioRecorderEditor && !this.copilot.isActive.value;
    },
    isEditorDisabled() {
      if (this.isGroupsDisabled && !this.isOnPrivateNote) {
        return true;
      }
      if (this.isGroupLeft && !this.isOnPrivateNote) {
        return true;
      }
      if (this.isAnnouncementModeRestricted && !this.isOnPrivateNote) {
        return true;
      }
      return (
        (this.isAWhatsAppChannel || this.isAPIInbox) &&
        !this.isOnPrivateNote &&
        !this.currentChat.can_reply
      );
    },
    // Signature preview for non-rich editor (WhatsApp, etc.)
    shouldShowSignaturePreview() {
      return (
        this.sendWithSignature &&
        this.messageSignature &&
        !this.isPrivate &&
        !this.showRichContentEditor
      );
    },
    signaturePosition() {
      return this.getSignatureSettingsForInbox(this.inboxId).position;
    },
    signatureSeparator() {
      return this.getSignatureSettingsForInbox(this.inboxId).separator;
    },
    formattedSignature() {
      if (!this.messageSignature) return '';
      return this.formatMessage(this.messageSignature, false, false);
    },
  },
  watch: {
    currentChat(conversation, oldConversation) {
      if (oldConversation && oldConversation.id !== conversation.id) {
        // Only update email fields when switching to a completely different conversation (by ID)
        // This prevents overwriting user input (e.g., CC/BCC fields) when performing actions
        // like self-assign or other updates that do not actually change the conversation context
        this.setCCAndToEmailsFromLastChat();
        this.subject = '';
        // Reset Copilot editor state (includes cancelling ongoing generation)
        this.copilot.reset();
        // Default to a note on calls so a reply is not sent as SMS by accident.
        // Only on open, so an agent who switches to reply keeps it.
        if (this.isVoiceCallConversation) {
          this.replyType = REPLY_EDITOR_MODES.NOTE;
        }
      }

      if (this.isInstagramReplyRestricted) {
        this.replyType = REPLY_EDITOR_MODES.NOTE;
        return;
      }

      if (this.isOnPrivateNote) {
        return;
      }

      this.replyType = this.isWithinMessagingWindow
        ? REPLY_EDITOR_MODES.REPLY
        : REPLY_EDITOR_MODES.NOTE;

      this.fetchAndSetReplyTo();
    },
    // When moving from one conversation to another, the store may not have the
    // list of all the messages. A fetch is subsequently made to get the messages.
    // This watcher handles two main cases:
    // 1. When switching conversations and messages are fetched/updated, ensures CC/BCC fields are set from the latest OUTGOING/INCOMING email (not activity/private messages).
    // 2. Fixes and issue where CC/BCC fields could be reset/lost after assignment/activity actions or message mutations that did not represent a true email context change.
    lastEmail: {
      handler(lastEmail) {
        if (!lastEmail) return;
        this.setCCAndToEmailsFromLastChat();
      },
      deep: true,
    },
    conversationIdByRoute(conversationId, oldConversationId) {
      if (conversationId !== oldConversationId) {
        this.advanceComposerGeneration();
        this.switchDraftContext(conversationId, this.effectiveReplyMode);
        this.resetRecorderAndClearAttachments();
        this.isQuoteRemoved = false;
      }
    },
    message() {
      // Autosave the current message draft.
      this.doAutoSaveDraft();
    },
    // Watches the whole condition, not just the contact. The capability arrives with the
    // inbox, and that request can land after this component mounts, so a watcher keyed on
    // the contact alone saw no capability, skipped the fetch and never ran again: a group
    // thread stayed without members until the agent switched conversations.
    groupMembersFetchTarget: {
      immediate: true,
      handler(target) {
        if (target && !this.isGroupMembersLoaded) {
          this.$store.dispatch('groupMembers/fetch', {
            contactId: this.groupContactId,
            inboxId: this.currentChat?.inbox_id,
          });
        }
      },
    },
    showWhatsappTemplates(isAvailable) {
      if (!isAvailable) this.hideWhatsappTemplatesModal();
    },
    showContentTemplates(isAvailable) {
      if (!isAvailable) this.hideContentTemplatesModal();
    },
    effectiveReplyMode(updatedReplyType) {
      this.$store.dispatch('draftMessages/setReplyEditorMode', {
        mode: updatedReplyType,
      });
      this.switchDraftContext(this.conversationIdByRoute, updatedReplyType);
      // The composer can change mode without the agent touching anything: a bot releases
      // the pending conversation it owned, the messaging window reopens, an Instagram
      // restriction lifts. Whatever is staged was produced under the old privacy but would
      // be sent under the new one, so a voice note recorded for the team could reach the
      // contact. The draft survives because switchDraftContext keeps one per mode;
      // attachments and a cited private note have no such split, so they go.
      //
      // Every path arrives here, whoever caused it: the composer cannot tell the agent
      // picking Reply from a bot releasing the conversation under them, and the message is
      // worth having either way, since what it reports is a file that will not be sent.
      // What it must not do is claim the contact was about to receive it, which is false in
      // one of the two directions.
      //
      // The announcement comes first, and the clearing is all done here rather than by the
      // callers: emptying the composer before the mode changes leaves this with nothing to
      // report, which is how a staged attachment and then a recording each stayed silent.
      this.advanceComposerGeneration(true);
      if (this.isRecordingAudio) this.onTypingOff();
      this.isRecordingAudio = false;
      this.resetRecorderAndClearAttachments();
      if (this.inReplyTo?.private && !this.isOnPrivateNote) {
        this.resetReplyToMessage();
      }
    },
  },

  mounted() {
    if (this.isInstagramReplyRestricted || this.isVoiceCallConversation) {
      this.replyType = REPLY_EDITOR_MODES.NOTE;
    }

    this.$store.dispatch('draftMessages/setReplyEditorMode', {
      mode: this.effectiveReplyMode,
    });
    this.switchDraftContext(
      this.conversationIdByRoute,
      this.effectiveReplyMode
    );
    // Bound directly rather than through useKeyboardEvents, because this has to
    // keep working even while the editor is focussed.
    document.addEventListener('paste', this.onPaste);
    this.setCCAndToEmailsFromLastChat();
    this.doAutoSaveDraft = debounce(
      () => {
        this.saveDraft(this.conversationIdByRoute, this.effectiveReplyMode);
      },
      500,
      true
    );

    this.fetchAndSetReplyTo();
    emitter.on(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.onReplyToMessage);

    // A hacky fix to solve the drag and drop
    // Is showing on top of new conversation modal drag and drop
    // TODO need to find a better solution
    emitter.on(
      BUS_EVENTS.NEW_CONVERSATION_MODAL,
      this.onNewConversationModalActive
    );
    emitter.on(CMD_AI_ASSIST, this.executeCopilotAction);
    emitter.on(
      BUS_EVENTS.INSERT_INTO_RICH_EDITOR,
      this.onInsertWhileCopilotActive
    );
  },
  unmounted() {
    document.removeEventListener('paste', this.onPaste);
    emitter.off(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.onReplyToMessage);
    emitter.off(
      BUS_EVENTS.NEW_CONVERSATION_MODAL,
      this.onNewConversationModalActive
    );
    emitter.off(CMD_AI_ASSIST, this.executeCopilotAction);
    emitter.off(
      BUS_EVENTS.INSERT_INTO_RICH_EDITOR,
      this.onInsertWhileCopilotActive
    );
  },
  methods: {
    openContactInfoTemplateModal() {
      this.requestContactInfoTemplatesOnly = true;
      this.showWhatsAppTemplatesModal = true;
    },
    getDraftKey(
      conversationId = this.conversationIdByRoute,
      replyType = this.effectiveReplyMode
    ) {
      return `draft-${conversationId}-${replyType}`;
    },
    getCopilotAcceptedMessage(replyType = this.effectiveReplyMode) {
      const key = this.getDraftKey(this.conversationIdByRoute, replyType);
      return this.copilotAcceptedMessages[key] || '';
    },
    setCopilotAcceptedMessage(message, replyType = this.effectiveReplyMode) {
      const key = this.getDraftKey(this.conversationIdByRoute, replyType);
      this.copilotAcceptedMessages[key] = trimContent(
        message || '',
        this.maxLength
      );
    },
    clearCopilotAcceptedMessage(replyType = this.effectiveReplyMode) {
      const key = this.getDraftKey(this.conversationIdByRoute, replyType);
      delete this.copilotAcceptedMessages[key];
    },
    handleInsert(article) {
      const { url, title } = article;
      // Removing empty lines from the title
      const lines = title.split('\n');
      const nonEmptyLines = lines.filter(line => line.trim() !== '');
      const filteredMarkdown = nonEmptyLines.join(' ');
      emitter.emit(
        BUS_EVENTS.INSERT_INTO_RICH_EDITOR,
        `[${filteredMarkdown}](${url})`
      );

      useTrack(CONVERSATION_EVENTS.INSERT_ARTICLE_LINK);
    },
    removeQuotedEmail() {
      this.isQuoteRemoved = true;
    },
    restoreQuotedEmail() {
      if (!this.isQuoteRemoved) {
        return false;
      }
      this.isQuoteRemoved = false;
      return true;
    },
    getMessageWithQuotedEmailText(message) {
      if (!this.shouldIncludeQuotedEmail) {
        return message;
      }

      return appendQuotedTextToMessage(
        message,
        this.quotedEmailText,
        this.quotedEmailHeader
      );
    },
    resetRecorderAndClearAttachments() {
      // Reset audio recorder UI state
      this.resetAudioRecorderInput();
      // Reset attached files
      this.attachedFiles = [];
    },
    saveDraft(conversationId, replyType) {
      if (this.message || this.message === '') {
        const key = this.getDraftKey(conversationId, replyType);
        const draftToSave = trimContent(this.message || '', this.maxLength);

        this.$store.dispatch('draftMessages/set', {
          key,
          message: draftToSave,
        });
      }
    },
    setToDraft(conversationId, replyType) {
      this.saveDraft(conversationId, replyType);
      this.message = '';
    },
    switchDraftContext(conversationId, replyMode) {
      if (
        this.draftConversationId === conversationId &&
        this.draftReplyMode === replyMode
      ) {
        return;
      }

      if (this.draftConversationId) {
        this.setToDraft(this.draftConversationId, this.draftReplyMode);
      }

      this.draftConversationId = conversationId;
      this.draftReplyMode = replyMode;
      this.getFromDraft();
    },
    getFromDraft() {
      if (this.conversationIdByRoute) {
        const key = this.getDraftKey();
        const messageFromStore =
          this.$store.getters['draftMessages/get'](key) || '';
        this.message = messageFromStore;
      }
    },
    removeFromDraft() {
      if (this.conversationIdByRoute) {
        const key = this.getDraftKey();
        this.$store.dispatch('draftMessages/delete', { key });
      }
    },
    isAValidEvent(selectedKey) {
      return (
        !this.showUserMentions &&
        !this.showMentions &&
        !this.showCannedMenu &&
        !this.showVariablesMenu &&
        !this.showScheduledMessageModal &&
        !this.showMacrosMenu &&
        this.isFocused &&
        this.isEditorHotKeyEnabled(selectedKey)
      );
    },
    applySignatureToMessage(message) {
      if (!this.sendWithSignature || !this.messageSignature) {
        return message;
      }
      const signatureSettings = {
        position: this.signaturePosition,
        separator: this.signatureSeparator,
      };
      return appendSignature(message, this.messageSignature, signatureSettings);
    },
    onPaste(e) {
      // Don't handle paste if compose new conversation modal is open
      if (this.newConversationModalActive) return;

      // Don't handle paste if editor is disabled
      if (this.isEditorDisabled) return;
      if (!this.showFileUpload && !this.isOnPrivateNote) return;

      // NOTE: Don't handle paste if scheduled message modal is open
      if (this.showScheduledMessageModal) return;

      // An empty file is refused at every other entry point, so it is refused here too. The
      // helper decides whether to say it out loud: a rich copy (a spreadsheet cell) brings an
      // invalid zero-byte attachment along with its text, and warning about that one would fire
      // on an ordinary paste, about a file nobody chose.
      const { files, shouldAlertEmpty } = usableFilesFromTransfer(
        e.clipboardData
      );
      if (shouldAlertEmpty) useAlert(this.$t('CONVERSATION.FILE_IS_EMPTY'));

      files
        .filter(file => {
          const isAllowed = isFileTypeAllowedForChannel(file, {
            channelType: this.channelType || this.inbox?.channel_type,
            medium: this.inbox?.medium,
            conversationType: this.conversationType,
            isInstagramChannel: this.isAnInstagramChannel,
            isOnPrivateNote: this.isOnPrivateNote,
          });

          if (!isAllowed) {
            useAlert(
              this.$t('CONVERSATION.FILE_TYPE_NOT_SUPPORTED', {
                fileName: file.name,
              })
            );
          }

          return isAllowed;
        })
        .forEach(file => {
          const { name, type, size } = file;
          this.stageFile({ name, type, size, file });
        });
    },
    toggleUserMention(currentMentionState) {
      this.showUserMentions = currentMentionState;
    },
    toggleCannedMenu(value) {
      this.showCannedMenu = value;
    },
    toggleVariablesMenu(value) {
      this.showVariablesMenu = value;
    },
    toggleMacrosMenu(value) {
      this.showMacrosMenu = value;
    },
    onExecuteMacro(macro) {
      const pending = this.macroExecution.execute(macro, this.currentChat.id);
      if (pending) {
        this.$refs.resolveAttributesModal?.open(
          pending.missing,
          pending.customAttributes
        );
      }
    },
    openWhatsappTemplateModal() {
      this.requestContactInfoTemplatesOnly = false;
      this.showWhatsAppTemplatesModal = true;
    },
    hideWhatsappTemplatesModal() {
      this.showWhatsAppTemplatesModal = false;
      this.requestContactInfoTemplatesOnly = false;
    },
    openContentTemplateModal() {
      this.showContentTemplatesModal = true;
    },
    hideContentTemplatesModal() {
      this.showContentTemplatesModal = false;
    },
    openScheduledMessageModal() {
      this.showScheduledMessageModal = true;
    },
    closeScheduledMessageModal() {
      this.showScheduledMessageModal = false;
    },
    async onScheduledMessageCreated() {
      this.closeScheduledMessageModal();
      this.clearMessage();
      // NOTE: Open sidebar and expand scheduled messages card
      this.$store.dispatch('updateUISettings', {
        is_contact_sidebar_open: true,
        is_scheduled_messages_open: true,
      });
    },
    confirmOnSendReply() {
      if (this.isReplyButtonDisabled) {
        return;
      }
      if (!this.showMentions) {
        const copilotAcceptedMessage = this.getCopilotAcceptedMessage();
        const isOnWhatsApp = this.isAWhatsAppChannel;
        // Instagram and TikTok do not support sending text and attachments in the same message.
        // For Instagram, combining them causes duplicate messages due to separate echo events per component.
        // For TikTok, the API rejects messages that mix text and media.
        // To handle both cases, text and attachments are always sent as separate messages.
        const isOnInstagram = this.isAnInstagramChannel;
        const isOnTiktok = this.isATiktokChannel;
        if ((isOnWhatsApp || isOnInstagram || isOnTiktok) && !this.isPrivate) {
          this.sendMessageAsMultipleMessages(
            this.message,
            copilotAcceptedMessage
          );
        } else {
          const messagePayload = this.getMessagePayload(this.message);
          this.sendMessage(
            messagePayload,
            this.message,
            copilotAcceptedMessage
          );
        }

        if (!this.isPrivate) {
          this.clearEmailField();
          this.isQuoteRemoved = false;
        }

        this.clearMessage();
        this.hideEmojiPicker();
      }
    },
    sendMessageAsMultipleMessages(message, copilotAcceptedMessage = '') {
      const messages = this.getMultipleMessagesPayload(message);
      messages.forEach(messagePayload => {
        this.sendMessage(
          messagePayload,
          messagePayload.message || '',
          copilotAcceptedMessage
        );
      });
    },
    sendMessageAnalyticsData(
      isPrivate,
      { editorMessage = '', copilotAcceptedMessage = '' } = {}
    ) {
      const normalizeForComparison = message => trimContent(message || '');

      const normalizedAcceptedMessage = normalizeForComparison(
        copilotAcceptedMessage
      );
      const normalizedEditorMessage = normalizeForComparison(editorMessage);

      if (normalizedAcceptedMessage && normalizedEditorMessage) {
        useTrack(CAPTAIN_EVENTS.AI_ASSISTED_MESSAGE_SENT, {
          conversationId: this.conversationIdByRoute,
          channelType: this.channelType,
          editedBeforeSend:
            normalizedAcceptedMessage !== normalizedEditorMessage,
          isPrivate,
        });
      }

      // Analytics data for message signature is enabled or not in channels
      return isPrivate
        ? useTrack(CONVERSATION_EVENTS.SENT_PRIVATE_NOTE)
        : useTrack(CONVERSATION_EVENTS.SENT_MESSAGE, {
            channelType: this.channelType,
            signatureEnabled: this.sendWithSignature,
            hasReplyTo: !!this.inReplyTo?.id,
          });
    },
    async onSendReply() {
      const undefinedVariables = getUndefinedVariablesInMessage({
        message: this.message,
        variables: this.messageVariables,
      });
      if (undefinedVariables.length > 0) {
        const undefinedVariablesCount =
          undefinedVariables.length > 1 ? undefinedVariables.length : 1;
        this.undefinedVariableMessage = this.$t(
          'CONVERSATION.REPLYBOX.UNDEFINED_VARIABLES.MESSAGE',
          {
            undefinedVariablesCount,
            undefinedVariables: undefinedVariables.join(', '),
          }
        );

        const ok = await this.$refs.confirmDialog.showConfirmation();
        if (ok) {
          this.confirmOnSendReply();
        }
      } else {
        this.confirmOnSendReply();
      }
    },
    async sendMessage(
      messagePayload,
      editorMessage = '',
      copilotAcceptedMessage = ''
    ) {
      try {
        await this.$store.dispatch(
          'createPendingMessageAndSend',
          messagePayload
        );
        emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        emitter.emit(BUS_EVENTS.MESSAGE_SENT);
        this.removeFromDraft();
        this.sendMessageAnalyticsData(messagePayload.private, {
          editorMessage,
          copilotAcceptedMessage,
        });
      } catch (error) {
        const errorMessage =
          error?.response?.data?.error || this.$t('CONVERSATION.MESSAGE_ERROR');
        useAlert(errorMessage);
      }
    },
    async onSendWhatsAppReply(messagePayload) {
      this.sendMessage({
        conversationId: this.currentChat.id,
        ...messagePayload,
      });
      this.hideWhatsappTemplatesModal();
    },
    async onSendContentTemplateReply(messagePayload) {
      this.sendMessage({
        conversationId: this.currentChat.id,
        ...messagePayload,
      });
      this.hideContentTemplatesModal();
    },
    replaceText(message) {
      const updatedMessage = replaceVariablesInMessage({
        message,
        variables: this.messageVariables,
      });

      setTimeout(() => {
        useTrack(CONVERSATION_EVENTS.INSERTED_A_CANNED_RESPONSE);
        this.message = updatedMessage;
      }, 100);
    },
    setReplyMode(mode = REPLY_EDITOR_MODES.REPLY) {
      // The clearing lives in the effectiveReplyMode watcher and only there. It ran here
      // too, ahead of the mode actually changing, so by the time the watcher looked there
      // was nothing left to report -- and it ran even when the mode did not change at all,
      // since `replyType` is only assigned below when a public reply is possible.
      this.$store.dispatch('draftMessages/setReplyEditorMode', { mode });
      if (this.canSendPublicReply) this.replyType = mode;
    },
    clearEditorSelection() {
      this.updateEditorSelectionWith = '';
    },
    addIntoEditor(content) {
      this.updateEditorSelectionWith = content;
      this.onFocus();
    },
    executeCopilotAction(action, data) {
      this.copilot.execute(action, data);
    },
    clearMessage() {
      // Sending consumes the composer as much as switching mode does: a capture
      // still uploading belongs to the message that just left, and would
      // otherwise land in the empty composer and ride along with the next one.
      this.advanceComposerGeneration();
      this.message = '';
      this.clearCopilotAcceptedMessage();
      this.attachedFiles = [];
      this.isRecordingAudio = false;
      this.resetReplyToMessage();
      this.resetAudioRecorderInput();
    },
    clearEmailField() {
      this.ccEmails = '';
      this.bccEmails = '';
      this.toEmails = '';
    },

    toggleEmojiPicker() {
      this.showEmojiPicker = !this.showEmojiPicker;
    },
    toggleAudioRecorder() {
      this.isRecordingAudio = !this.isRecordingAudio;
      if (!this.isRecordingAudio) {
        this.resetAudioRecorderInput();
        this.onTypingOff();
      } else {
        this.recordingGeneration = this.composerGeneration;
        this.onRecording();
      }
    },
    toggleAudioRecorderPlayPause() {
      if (!this.$refs.audioRecorderInput) return;
      if (!this.recordingAudioState) {
        this.$refs.audioRecorderInput.stopRecording();
      } else {
        this.onTypingOff();
        this.$refs.audioRecorderInput.playPause();
      }
    },
    hideEmojiPicker() {
      if (this.showEmojiPicker) {
        this.toggleEmojiPicker();
      }
    },
    onTypingOn() {
      this.toggleTyping('on');
    },
    onRecording() {
      this.toggleTyping('recording');
    },
    onTypingOff() {
      this.toggleTyping('off');
    },
    onBlur() {
      this.isFocused = false;
      this.saveDraft(this.conversationIdByRoute, this.effectiveReplyMode);
    },
    onFocus() {
      this.isFocused = true;
    },
    onRecordProgressChanged(duration) {
      this.recordingAudioDurationText = duration;
    },
    onFinishRecorder(file) {
      this.recordingAudioState = 'stopped';

      this.removeRecordedAudio();

      // Added a new key isVoiceMessage to the file to identify recorded audio
      // Because to filter and show only non recorded audio and other attachments
      // Stamped with what the composer was when the mic was armed — the agent
      // spoke and the audio was converted since, and either could have outlasted
      // the mode the recording was meant for.
      const autoRecordedFile = {
        ...file,
        isVoiceMessage: true,
        composerGeneration: this.recordingGeneration,
      };
      return file && this.stageFile(autoRecordedFile);
    },
    onRecordError() {
      this.toggleAudioRecorder();
      useAlert(this.$t('CONVERSATION.REPLYBOX.AUDIO_CONVERSION_FAILED'));
    },
    toggleTyping(status) {
      const conversationId = this.currentChat.id;
      const isPrivate = this.isPrivate;

      if (!conversationId) {
        return;
      }

      this.$store.dispatch('conversationTypingStatus/toggleTyping', {
        status,
        conversationId,
        isPrivate,
      });
    },
    // Every capture goes through here: the recorder, the clip button, drag and
    // drop, and paste. MP3 conversion and the upload that follows are async, so
    // the composer can move to a public reply — or to another conversation —
    // before the file ever arrives, and attachFile would then stage it under a
    // privacy the agent never chose.
    stageFile(file) {
      if (!file) return;

      // Never a positional second argument here: this is wired straight to the
      // uploader's `input-file`, which emits (newFile, oldFile) and re-emits on
      // every progress update. A recorder capture arrives already stamped, from
      // when the mic was armed.
      if (file.composerGeneration === undefined) {
        file.composerGeneration = this.composerGeneration;
      }
      this.onFileUpload(file);
    },
    advanceComposerGeneration(announceable = false) {
      // Whatever is already staged is discarded right here, by the reset that follows, so
      // it is said now. Waiting for an upload callback loses every capture that had already
      // finished, which is the ordinary shape of this: the recording is sitting in the
      // composer when the bot hands the conversation back.
      // Only a capture still uploading needs a marker, and only until it lands. Each is
      // kept beside the others rather than replacing them: a marker belongs to whatever was
      // staged under that generation, and a later transition has no business answering, or
      // silencing, an earlier one.
      if (announceable && !this.announceVisibleDiscard()) {
        this.composerDropGenerations.push(this.composerGeneration);
        if (this.composerDropGenerations.length > MAX_PENDING_DISCARD_MARKERS) {
          this.composerDropGenerations.shift();
        }
      }
      this.composerGeneration += 1;
    },
    announceVisibleDiscard() {
      const staged = this.attachedFiles;
      if (!staged.length && !this.isRecordingAudio) return false;

      this.announceDiscard(
        this.isRecordingAudio || staged.some(file => file.isVoiceMessage)
      );
      return true;
    },
    // A capture that arrives for a composer that has moved on is thrown away, and the agent
    // is told only when they have no way of working out why on their own.
    //
    // Leaving note mode is that case: nothing the agent did causes it — a bot releases the
    // conversation it owned, the messaging window reopens, an Instagram restriction lifts —
    // so what they staged disappears with the composer looking untouched. Navigating away
    // and sending are their own actions, with the composer visibly resetting in front of
    // them, and an alert on those is noise on the ordinary case.
    //
    // The marker is consumed, so a batch staged together and invalidated by one transition
    // is one message rather than a stack of identical ones.
    discardStagedCapture(file, generation) {
      const marker = this.composerDropGenerations.indexOf(generation);
      if (marker === -1) return;

      this.composerDropGenerations.splice(marker, 1);
      this.announceDiscard(Boolean(file?.isVoiceMessage));
    },
    announceDiscard(isRecording) {
      useAlert(
        isRecording
          ? this.$t('CONVERSATION.REPLYBOX.RECORDING_DISCARDED_ON_MODE_CHANGE')
          : this.$t('CONVERSATION.REPLYBOX.ATTACHMENT_DISCARDED_ON_MODE_CHANGE')
      );
    },
    attachFile({ blob, file }) {
      const generation = file?.composerGeneration;
      // Checked here so a stale recording can't clear a newer one below.
      if (generation !== this.composerGeneration) {
        this.discardStagedCapture(file, generation);
        return;
      }

      if (file?.isVoiceMessage) {
        this.removeRecordedAudio();
      }

      if (!this.showFileUpload && !this.isOnPrivateNote) return;

      const reader = new FileReader();
      reader.readAsDataURL(file.file);
      reader.onloadend = () => {
        // Reading the file is async as well, so the mode can change between the
        // two. The push is the only moment that decides what gets sent, so it is
        // where the capture has to still be current.
        if (generation !== this.composerGeneration) {
          this.discardStagedCapture(file, generation);
          return;
        }

        this.attachedFiles.push({
          currentChatId: this.currentChat.id,
          resource: blob || file,
          isPrivate: this.isPrivate,
          thumb: reader.result,
          blobSignedId: blob ? blob.signed_id : undefined,
          isVoiceMessage: file?.isVoiceMessage || false,
        });
      };
    },
    removeAttachment(attachments) {
      this.attachedFiles = attachments;
    },
    setReplyToInPayload(payload) {
      if (this.inReplyTo?.id) {
        return {
          ...payload,
          contentAttributes: {
            ...payload.contentAttributes,
            in_reply_to: this.inReplyTo.id,
          },
        };
      }

      return payload;
    },
    getMultipleMessagesPayload(message) {
      const multipleMessagePayload = [];

      const messageWithSignature = this.applySignatureToMessage(message);

      if (this.attachedFiles?.length) {
        let caption =
          this.isAnInstagramChannel || this.isATiktokChannel
            ? ''
            : messageWithSignature;
        this.attachedFiles.forEach(attachment => {
          const attachedFile = this.globalConfig.directUploadsEnabled
            ? attachment.blobSignedId
            : attachment.resource.file;
          let attachmentPayload = {
            conversationId: this.currentChat.id,
            files: [attachedFile],
            private: false,
            message: caption,
            sender: this.sender,
            isVoiceMessage: attachment.isVoiceMessage || false,
          };

          attachmentPayload = this.setReplyToInPayload(attachmentPayload);
          multipleMessagePayload.push(attachmentPayload);
          // For WhatsApp, only the first attachment gets a caption
          if (!this.isAnInstagramChannel) caption = '';
        });
      }

      const hasNoAttachments = !this.attachedFiles?.length;
      // For Instagram and TikTok, text must always be sent as a separate message (no captions on attachments).
      // For WhatsApp, we only need a text message if there are no attachments.
      if (
        ((this.isAnInstagramChannel || this.isATiktokChannel) &&
          this.message) ||
        (!(this.isAnInstagramChannel || this.isATiktokChannel) &&
          hasNoAttachments)
      ) {
        let messagePayload = {
          conversationId: this.currentChat.id,
          message: messageWithSignature,
          private: false,
          sender: this.sender,
        };

        messagePayload = this.setReplyToInPayload(messagePayload);

        multipleMessagePayload.push(messagePayload);
      }

      return multipleMessagePayload;
    },
    getMessagePayload(message) {
      let finalMessage = this.getMessageWithQuotedEmailText(message);
      if (!this.isPrivate) {
        finalMessage = this.applySignatureToMessage(finalMessage);
      }

      let messagePayload = {
        conversationId: this.currentChat.id,
        message: finalMessage,
        private: this.isPrivate,
        sender: this.sender,
      };
      messagePayload = this.setReplyToInPayload(messagePayload);

      if (this.attachedFiles?.length) {
        messagePayload.files = [];
        this.attachedFiles.forEach(attachment => {
          if (this.globalConfig.directUploadsEnabled) {
            messagePayload.files.push(attachment.blobSignedId);
          } else {
            messagePayload.files.push(attachment.resource.file);
          }
          if (attachment.isVoiceMessage) {
            messagePayload.isVoiceMessage = true;
          }
        });
      }

      if (this.ccEmails && !this.isOnPrivateNote) {
        messagePayload.ccEmails = this.ccEmails;
      }

      if (this.bccEmails && !this.isOnPrivateNote) {
        messagePayload.bccEmails = this.bccEmails;
      }

      if (this.toEmails && !this.isOnPrivateNote) {
        messagePayload.toEmails = this.toEmails;
      }

      if (this.subject && !this.isOnPrivateNote) {
        messagePayload.subject = this.subject;
      }
      return messagePayload;
    },
    setCcEmails(value) {
      this.bccEmails = value.bccEmails;
      this.ccEmails = value.ccEmails;
    },
    setCCAndToEmailsFromLastChat() {
      const conversationContact = this.currentChat?.meta?.sender?.email || '';
      const { email: inboxEmail, forward_to_email: forwardToEmail } =
        this.inbox;

      const { cc, bcc, to } = getRecipients(
        this.lastEmail,
        conversationContact,
        inboxEmail,
        forwardToEmail
      );

      this.toEmails = to.join(', ');
      this.ccEmails = cc.join(', ');
      this.bccEmails = bcc.join(', ');
    },
    fetchAndSetReplyTo() {
      const replyStorageKey = LOCAL_STORAGE_KEYS.MESSAGE_REPLY_TO;
      const replyToMessageId = LocalStorage.getFromJsonStore(
        replyStorageKey,
        this.conversationId
      );

      const target = this.currentChat?.messages?.find(message => {
        if (message.id === replyToMessageId) {
          return true;
        }
        return false;
      });

      // Replying to a private note must keep the composer internal: switching
      // to NOTE mode prevents leaking the note's id into an outbound reply's
      // `in_reply_to` and keeps the cited preview visible to agents only.
      if (target?.private && !this.isOnPrivateNote) {
        this.setReplyMode(REPLY_EDITOR_MODES.NOTE);
      }

      this.inReplyTo = target ?? {};
    },
    onReplyToMessage() {
      this.fetchAndSetReplyTo();
      if (this.inReplyTo) {
        this.$nextTick(() => {
          const pos = this.isSignatureEnabledForInbox ? 'start' : 'end';
          this.messageEditor?.focusEditorInputField(pos);
        });
      }
    },
    resetReplyToMessage() {
      const replyStorageKey = LOCAL_STORAGE_KEYS.MESSAGE_REPLY_TO;
      LocalStorage.deleteFromJsonStore(replyStorageKey, this.conversationId);
      emitter.emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE);
    },
    onNewConversationModalActive(isActive) {
      // Issue is if the new conversation modal is open and we drag and drop the file
      // then the file is not getting attached to the new conversation modal
      // and it is getting attached to the current conversation reply box
      // so to fix this we are removing the drag and drop event listener from the current conversation reply box
      // When new conversation modal is open
      this.newConversationModalActive = isActive;
    },
    onSearchPopoverClose() {
      this.showArticleSearchPopover = false;
    },
    toggleInsertArticle() {
      this.showArticleSearchPopover = !this.showArticleSearchPopover;
    },
    resetAudioRecorderInput() {
      this.recordingAudioDurationText = '00:00';
      this.isRecordingAudio = false;
      this.recordingAudioState = '';
      // Only clear the recorded audio when we click toggle button.
      this.removeRecordedAudio();
    },
    removeRecordedAudio() {
      this.attachedFiles = this.attachedFiles.filter(
        file => !file?.isVoiceMessage
      );
    },
    toggleEditorSize() {
      this.$emit('toggleEditorSize');
      this.$nextTick(() => this.messageEditor?.focusEditorInputField());
    },
    onSubmitCopilotReply() {
      const acceptedMessage = this.copilot.accept();
      this.message = acceptedMessage;
      this.setCopilotAcceptedMessage(acceptedMessage);
    },
    onInsertWhileCopilotActive(content) {
      if (!this.copilot.isActive.value) return;
      this.copilot.reset();
      const channelType = getEffectiveChannelType(
        this.channelType,
        this.inbox?.medium || ''
      );
      const insert = stripUnsupportedMarkdown(
        content,
        this.isPrivate ? 'Context::PrivateNote' : channelType,
        false
      );
      // The signature is added when the message is sent (getMessagePayload), so the draft
      // carries none to keep after the inserted text.
      const body = this.message;
      this.message = body.trim() ? `${body.trimEnd()}\n${insert}` : insert;
    },
  },
};
</script>

<template>
  <ReplyBoxBanner :message="message" :is-on-private-note="isOnPrivateNote" />
  <div class="reply-box" :class="replyBoxClass">
    <ReplyTopPanel
      :mode="replyType"
      :conversation-id="conversationId"
      :is-reply-restricted="!canSendPublicReply"
      :disabled="
        (copilot.isActive.value && copilot.isButtonDisabled.value) ||
        showAudioRecorderEditor
      "
      :is-editor-disabled="isEditorDisabled"
      :is-message-length-reaching-threshold="isMessageLengthReachingThreshold"
      :characters-remaining="charactersRemaining"
      :editor-content="message"
      :has-content="hasMeaningfulEditorContent"
      @set-reply-mode="setReplyMode"
      @toggle-editor-size="toggleEditorSize"
      @toggle-copilot="copilot.toggleEditor"
      @execute-copilot-action="executeCopilotAction"
    />
    <ArticleSearchPopover
      v-if="showArticleSearchPopover && connectedPortalSlug"
      :selected-portal-slug="connectedPortalSlug"
      @insert="handleInsert"
      @close="onSearchPopoverClose"
    />
    <Transition
      mode="out-in"
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0 translate-y-2 scale-[0.98]"
      enter-to-class="opacity-100 translate-y-0 scale-100"
      leave-active-class="transition-all duration-200 ease-in"
      leave-from-class="opacity-100 translate-y-0 scale-100"
      leave-to-class="opacity-0 translate-y-2 scale-[0.98]"
    >
      <div :key="copilot.editorTransitionKey.value" class="reply-box__top">
        <ReplyToMessage
          v-if="shouldShowReplyToMessage"
          :message="inReplyTo"
          @dismiss="resetReplyToMessage"
        />
        <EmojiIconPicker
          v-if="showEmojiPicker"
          v-on-clickaway="hideEmojiPicker"
          mode="emoji"
          class="emoji-dialog"
          :class="{
            'emoji-dialog--expanded': isOnExpandedLayout,
          }"
          @select="addIntoEditor($event.value)"
        />
        <ReplyEmailHead
          v-if="showReplyHead && isDefaultEditorMode"
          :key="currentChat.id"
          v-model:cc-emails="ccEmails"
          v-model:bcc-emails="bccEmails"
          v-model:to-emails="toEmails"
          v-model:subject="subject"
        />
        <AudioRecorder
          v-if="showAudioRecorderEditor"
          ref="audioRecorderInput"
          :audio-record-format="audioRecordFormat"
          @recorder-progress-changed="onRecordProgressChanged"
          @finish-record="onFinishRecorder"
          @record-error="onRecordError"
          @play="recordingAudioState = 'playing'"
          @pause="recordingAudioState = 'paused'"
        />
        <CopilotEditorSection
          v-if="copilot.isActive.value && !showAudioRecorderEditor"
          :show-copilot-editor="copilot.showEditor.value"
          :is-generating-content="copilot.isGenerating.value"
          :generated-content="copilot.generatedContent.value"
          :placeholder="$t('CONVERSATION.FOOTER.COPILOT_MSG_INPUT')"
          @focus="onFocus"
          @blur="onBlur"
          @clear-selection="clearEditorSelection"
          @close="copilot.showEditor.value = false"
          @content-ready="copilot.setContentReady"
          @send="copilot.sendFollowUp"
        />
        <WootMessageEditor
          v-else-if="!showAudioRecorderEditor"
          ref="messageEditor"
          v-model="message"
          :conversation-id="conversationId"
          :editor-id="editorStateId"
          class="input popover-prosemirror-menu resizable-editor-split"
          :is-private="isOnPrivateNote"
          :placeholder="messagePlaceHolder"
          :update-selection-with="updateEditorSelectionWith"
          :min-height="4"
          :disabled="isEditorDisabled"
          enable-insert-events
          :enable-macros="isMacrosEnabled"
          enable-variables
          :variables="messageVariables"
          :signature="messageSignature"
          allow-signature
          :signature-position-override="signaturePosition"
          :signature-separator-override="signatureSeparator"
          :channel-type="channelType"
          :medium="inbox.medium"
          :is-group-conversation="isGroupConversation"
          :group-contact-id="groupContactId"
          :inbox-phone-number="inboxPhoneNumber"
          @typing-off="onTypingOff"
          @typing-on="onTypingOn"
          @focus="onFocus"
          @blur="onBlur"
          @toggle-user-mention="toggleUserMention"
          @toggle-canned-menu="toggleCannedMenu"
          @toggle-variables-menu="toggleVariablesMenu"
          @toggle-macros-menu="toggleMacrosMenu"
          @execute-macro="onExecuteMacro"
          @clear-selection="clearEditorSelection"
          @execute-copilot-action="executeCopilotAction"
        >
          <template #footer>
            <QuotedEmailPreview
              v-if="shouldIncludeQuotedEmail"
              :key="conversationId"
              :quoted-email-text="quotedEmailText"
              :header="quotedEmailHeader"
              @remove="removeQuotedEmail"
            />
          </template>
        </WootMessageEditor>

        <div
          v-if="hasAttachments && isDefaultEditorMode"
          class="bg-transparent py-0 mb-2"
          @paste="onPaste"
        >
          <AttachmentPreview
            class="mt-2"
            :attachments="attachedFiles"
            @remove-attachment="removeAttachment"
          />
        </div>
        <MessageSignatureMissingAlert
          v-if="
            isSignatureEnabledForInbox &&
            !isSignatureAvailable &&
            isDefaultEditorMode
          "
          class="mb-2"
        />
      </div>
    </Transition>

    <Transition
      mode="out-in"
      enter-active-class="transition-all duration-300 ease-out"
      enter-from-class="opacity-0 translate-y-2 scale-[0.98]"
      enter-to-class="opacity-100 translate-y-0 scale-100"
      leave-active-class="transition-all duration-200 ease-in"
      leave-from-class="opacity-100 translate-y-0 scale-100"
      leave-to-class="opacity-0 translate-y-2 scale-[0.98]"
    >
      <CopilotReplyBottomPanel
        v-if="copilot.isActive.value"
        key="copilot-bottom-panel"
        :is-generating-content="copilot.isButtonDisabled.value"
        @submit="onSubmitCopilotReply"
        @cancel="copilot.reset"
      />
      <ReplyBottomPanel
        v-else
        key="reply-bottom-panel"
        :conversation-id="conversationId"
        :enable-multiple-file-upload="enableMultipleFileUpload"
        :enable-whats-app-templates="showWhatsappTemplates"
        :enable-content-templates="showContentTemplates"
        :inbox="inbox"
        :is-on-private-note="isOnPrivateNote"
        :is-recording-audio="isRecordingAudio"
        :is-send-disabled="isReplyButtonDisabled"
        :is-note="isPrivate"
        :is-editor-disabled="isEditorDisabled"
        :on-file-upload="stageFile"
        :on-send="onSendReply"
        :conversation-type="conversationType"
        :recording-audio-duration-text="recordingAudioDurationText"
        :recording-audio-state="recordingAudioState"
        :send-button-text="replyButtonLabel"
        :show-audio-recorder="showAudioRecorder"
        :show-emoji-picker="showEmojiPicker"
        :show-file-upload="showFileUpload"
        :toggle-audio-recorder-play-pause="toggleAudioRecorderPlayPause"
        :toggle-audio-recorder="toggleAudioRecorder"
        :toggle-emoji-picker="toggleEmojiPicker"
        :message="message"
        :portal-slug="connectedPortalSlug"
        :new-conversation-modal-active="newConversationModalActive"
        :show-schedule-options="!isPrivate"
        @select-whatsapp-template="openWhatsappTemplateModal"
        @select-content-template="openContentTemplateModal"
        @toggle-insert-article="toggleInsertArticle"
        @schedule-message="openScheduledMessageModal"
        @request-contact-info-template="openContactInfoTemplateModal"
      />
    </Transition>

    <WhatsappTemplates
      :inbox-id="inbox.id"
      :show="showWhatsAppTemplatesModal"
      :send-rendered-content="isAPIInbox"
      :request-contact-info-only="requestContactInfoTemplatesOnly"
      @close="hideWhatsappTemplatesModal"
      @on-send="onSendWhatsAppReply"
      @cancel="hideWhatsappTemplatesModal"
    />

    <ContentTemplates
      :inbox-id="inbox.id"
      :show="showContentTemplatesModal"
      @close="hideContentTemplatesModal"
      @on-send="onSendContentTemplateReply"
      @cancel="hideContentTemplatesModal"
    />

    <ScheduledMessageModal
      v-model:show="showScheduledMessageModal"
      :conversation-id="conversationId"
      :inbox-id="inbox.id"
      :initial-content="message"
      :initial-attachment="attachedFiles[0] || null"
      @scheduled-message-created="onScheduledMessageCreated"
    />
    <ConversationResolveAttributesModal
      ref="resolveAttributesModal"
      @submit="macroExecution.submitPendingAttributes"
      @close="macroExecution.dismissPendingAttributes"
    />

    <woot-confirm-modal
      ref="confirmDialog"
      :title="$t('CONVERSATION.REPLYBOX.UNDEFINED_VARIABLES.TITLE')"
      :description="undefinedVariableMessage"
    />
  </div>
</template>

<style lang="scss" scoped>
.send-button {
  @apply mb-0;
}

.reply-box {
  @apply relative mb-2 mx-2 border border-n-weak rounded-xl bg-n-solid-1;

  &.is-private {
    @apply bg-n-solid-amber dark:border-n-amber-3/10 border-n-amber-12/5;
  }
}

.send-button {
  @apply mb-0;
}

.reply-box__top {
  @apply relative py-0 px-3 -mt-px;
}

.emoji-dialog {
  @apply top-[unset] -bottom-10 ltr:-left-80 ltr:right-[unset] rtl:left-[unset] rtl:-right-80;

  &::before {
    filter: drop-shadow(0px 4px 4px rgba(0, 0, 0, 0.08));
    @apply ltr:-right-4 bottom-2 rtl:-left-4 ltr:rotate-[270deg] rtl:rotate-[90deg];
  }
}

.emoji-dialog--expanded {
  @apply left-[unset] bottom-0 absolute z-[100];

  &::before {
    transform: rotate(0deg);
    @apply ltr:left-1 rtl:right-1 -bottom-2;
  }
}
</style>
