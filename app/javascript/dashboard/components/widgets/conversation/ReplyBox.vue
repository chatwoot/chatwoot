<script>
import { defineAsyncComponent, useTemplateRef } from 'vue';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useTrack } from 'dashboard/composables';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

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
import StickerPickerDialog from 'dashboard/components-next/whatsapp/StickerPickerDialog.vue';
import AttachedContactsPreview from 'dashboard/components-next/Conversation/AttachedContactsPreview.vue';
import ContactAttachmentModal from 'dashboard/components-next/Conversation/ContactAttachmentModal.vue';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import AudioRecorder from 'dashboard/components/widgets/WootWriter/AudioRecorder.vue';
import { AUDIO_FORMATS } from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { CMD_AI_ASSIST } from 'dashboard/helper/commandbar/events';
import {
  getMessageVariables,
  getUndefinedVariablesInMessage,
} from '@chatwoot/utils';
import WhatsappTemplates from './WhatsappTemplates/Modal.vue';
import ScheduledMessageModal from 'dashboard/routes/dashboard/conversation/scheduledMessages/ScheduledMessageModal.vue';
import ContentTemplates from './ContentTemplates/ContentTemplatesModal.vue';
import conversationApi from 'dashboard/api/inbox/conversation';
import { MESSAGE_MAX_LENGTH } from 'shared/helpers/MessageTypeHelper';
import inboxMixin, { INBOX_FEATURES } from 'shared/mixins/inboxMixin';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { trimContent, debounce, getRecipients } from '@chatwoot/utils';
import wootConstants from 'dashboard/constants/globals';
import {
  extractQuotedEmailText,
  buildQuotedEmailHeader,
  truncatePreviewText,
  appendQuotedTextToMessage,
} from 'dashboard/helper/quotedEmailHelper';
import {
  CONVERSATION_EVENTS,
  CAPTAIN_EVENTS,
} from '../../../helper/AnalyticsHelper/events';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import {
  appendSignature,
  removeSignature,
  getEffectiveChannelType,
} from 'dashboard/helper/editorHelper';
import { useCopilotReply } from 'dashboard/composables/useCopilotReply';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { isFileTypeAllowedForChannel } from 'shared/helpers/FileHelper';

import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import { emitter } from 'shared/helpers/mitt';

const GROUP_CONTACT_MENTION_REGEX =
  /\[@([^\]]+)\]\(mention:\/\/group[_-]contact\/(\d+)\/([^)]+)\)|mention:\/\/group[_-]contact\/(\d+)\/([^\s)]+)/g;

const EmojiInput = defineAsyncComponent(
  () => import('shared/components/emoji/EmojiInput.vue')
);

export default {
  components: {
    ArticleSearchPopover,
    AttachmentPreview,
    AttachedContactsPreview,
    AudioRecorder,
    ReplyBoxBanner,
    EmojiInput,
    MessageSignatureMissingAlert,
    ReplyBottomPanel,
    ReplyEmailHead,
    ReplyToMessage,
    ReplyTopPanel,
    ContentTemplates,
    ContactAttachmentModal,
    WhatsappTemplates,
    ScheduledMessageModal,
    WootMessageEditor,
    QuotedEmailPreview,
    StickerPickerDialog,
    CopilotEditorSection,
    CopilotReplyBottomPanel,
  },
  mixins: [inboxMixin, fileUploadMixin, keyboardEventListenerMixins],
  props: {
    popOutReplyBox: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['update:popOutReplyBox', 'toggleEditorSize'],
  setup() {
    const {
      uiSettings,
      isEditorHotKeyEnabled,
      fetchSignatureFlagFromUISettings,
      setQuotedReplyFlagForInbox,
      fetchQuotedReplyFlagFromUISettings,
    } = useUISettings();

    const replyEditor = useTemplateRef('replyEditor');
    const messageEditor = useTemplateRef('messageEditor');
    const copilot = useCopilotReply();
    const shortcutKey = useKbd(['$mod', '+', 'enter']);

    return {
      uiSettings,
      isEditorHotKeyEnabled,
      fetchSignatureFlagFromUISettings,
      setQuotedReplyFlagForInbox,
      fetchQuotedReplyFlagFromUISettings,
      replyEditor,
      messageEditor,
      copilot,
      shortcutKey,
    };
  },
  data() {
    return {
      message: '',
      showScheduledMessageModal: false,
      inReplyTo: {},
      isFocused: false,
      showEmojiPicker: false,
      attachedFiles: [],
      attachedContacts: [],
      isRecordingAudio: false,
      recordingAudioState: '',
      recordingAudioDurationText: '',
      replyType: REPLY_EDITOR_MODES.REPLY,
      bccEmails: '',
      ccEmails: '',
      toEmails: '',
      doAutoSaveDraft: () => {},
      showWhatsAppTemplatesModal: false,
      showContentTemplatesModal: false,
      showContactAttachmentModal: false,
      showStickerPicker: false,
      updateEditorSelectionWith: '',
      undefinedVariableMessage: '',
      showMentions: false,
      showUserMentions: false,
      showGroupMentions: false,
      showCannedMenu: false,
      showVariablesMenu: false,
      newConversationModalActive: false,
      showArticleSearchPopover: false,
      hasRecordedAudio: false,
      copilotAcceptedMessages: {},
      groupMentionContacts: [],
      isLoadingGroupMentionContacts: false,
      groupMentionFetchTimeout: null,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      messageSignature: 'getMessageSignature',
      currentUser: 'getCurrentUser',
      lastEmail: 'getLastEmailInSelectedChat',
      globalConfig: 'globalConfig/get',
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    currentContact() {
      const senderId = this.currentChat?.meta?.sender?.id;
      if (!senderId) return {};
      return this.$store.getters['contacts/getContact'](senderId);
    },
    canUseGroupMentions() {
      return (
        this.currentChat?.group &&
        this.isAUnoapiChannel &&
        !this.isOnPrivateNote
      );
    },
    shouldShowReplyToMessage() {
      return (
        this.inReplyTo?.id &&
        !this.isPrivate &&
        this.inboxHasFeature(INBOX_FEATURES.REPLY_TO) &&
        !this.is360DialogWhatsAppChannel &&
        !this.copilot.isActive.value
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
    isPrivate() {
      if (
        this.currentChat.can_reply ||
        this.isAWhatsAppChannel ||
        this.isAPIInbox
      ) {
        return this.isOnPrivateNote;
      }
      return true;
    },
    isReplyRestricted() {
      return (
        !this.currentChat?.can_reply &&
        !(this.isAWhatsAppChannel || this.isAPIInbox)
      );
    },
    inboxId() {
      return this.currentChat.inbox_id;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },
    messagePlaceHolder() {
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
      if (
        this.hasAttachments ||
        this.hasRecordedAudio ||
        this.hasAttachedContacts
      ) {
        return false;
      }

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
        this.isANotificaMeChannel ||
        this.isAnInstagramChannel ||
        this.channelType === INBOX_TYPES.INTERNAL ||
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
        'is-focused':
          this.isFocused || this.hasAttachments || this.hasAttachedContacts,
      };
    },
    hasAttachments() {
      return this.attachedFiles.length;
    },
    hasAttachedContacts() {
      return this.attachedContacts.length;
    },
    showAudioRecorder() {
      return !this.isOnPrivateNote && this.showFileUpload;
    },
    showAudioRecorderEditor() {
      return this.showAudioRecorder && this.isRecordingAudio;
    },
    isOnPrivateNote() {
      return this.replyType === REPLY_EDITOR_MODES.NOTE;
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
      return true;
    },
    isSignatureEnabledForInbox() {
      return !this.isPrivate && this.sendWithSignature;
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
      return `draft-${this.conversationIdByRoute}-${this.replyType}`;
    },
    audioRecordFormat() {
      if (
        this.isAWhatsAppChannel ||
        this.isATelegramChannel ||
        this.isANotificaMeChannel
      ) {
        return AUDIO_FORMATS.MP3;
      }
      if (this.isAPIInbox) {
        return AUDIO_FORMATS.MP3;
      }
      return AUDIO_FORMATS.WAV;
    },
    messageVariables() {
      const variables = getMessageVariables({
        conversation: this.currentChat,
        contact: this.currentContact,
        inbox: this.inbox,
      });
      return variables;
    },
    connectedPortalSlug() {
      const { help_center: portal = {} } = this.inbox;
      const { slug = '' } = portal;
      return slug;
    },
    isQuotedEmailReplyEnabled() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.QUOTED_EMAIL_REPLY
      );
    },
    quotedReplyPreference() {
      if (!this.isAnEmailChannel || !this.isQuotedEmailReplyEnabled) {
        return false;
      }

      return !!this.fetchQuotedReplyFlagFromUISettings(this.channelType);
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
    quotedEmailPreviewText() {
      return truncatePreviewText(this.quotedEmailText, 80);
    },
    shouldShowQuotedReplyToggle() {
      return (
        this.isAnEmailChannel &&
        !this.isOnPrivateNote &&
        this.isQuotedEmailReplyEnabled
      );
    },
    shouldShowQuotedPreview() {
      return (
        this.shouldShowQuotedReplyToggle &&
        this.quotedReplyPreference &&
        !!this.quotedEmailText
      );
    },
    isDefaultEditorMode() {
      return !this.showAudioRecorderEditor && !this.copilot.isActive.value;
    },
    isEditorDisabled() {
      return (
        (this.isAWhatsAppChannel || this.isAPIInbox) &&
        !this.isOnPrivateNote &&
        !this.currentChat.can_reply
      );
    },
  },
  watch: {
    currentChat(conversation, oldConversation) {
      const { can_reply: canReply } = conversation;
      if (oldConversation && oldConversation.id !== conversation.id) {
        // Only update email fields when switching to a completely different conversation (by ID)
        // This prevents overwriting user input (e.g., CC/BCC fields) when performing actions
        // like self-assign or other updates that do not actually change the conversation context
        this.setCCAndToEmailsFromLastChat();
        // Reset Copilot editor state (includes cancelling ongoing generation)
        this.copilot.reset();
      }

      if (this.isOnPrivateNote) {
        return;
      }

      if (canReply || this.isAWhatsAppChannel || this.isAPIInbox) {
        this.replyType = REPLY_EDITOR_MODES.REPLY;
      } else {
        this.replyType = REPLY_EDITOR_MODES.NOTE;
      }

      this.fetchAndSetReplyTo();
    },
    showGroupMentions(value) {
      if (value) this.fetchGroupMentionContacts(this.groupMentionSearchTerm());
      if (!value) this.groupMentionContacts = [];
    },
    message() {
      // Autosave the current message draft.
      this.doAutoSaveDraft();
      if (this.showGroupMentions) this.debouncedFetchGroupMentionContacts();
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
        this.setToDraft(oldConversationId, this.replyType);
        this.getFromDraft();
        this.resetRecorderAndClearAttachments();
      }
    },
    replyType(updatedReplyType, oldReplyType) {
      this.setToDraft(this.conversationIdByRoute, oldReplyType);
      this.getFromDraft();
    },
  },

  mounted() {
    this.getFromDraft();
    // Don't use the keyboard listener mixin here as the events here are supposed to be
    // working even if the editor is focussed.
    document.addEventListener('paste', this.onPaste);
    document.addEventListener('keydown', this.handleKeyEvents);
    this.setCCAndToEmailsFromLastChat();
    this.doAutoSaveDraft = debounce(
      () => {
        this.saveDraft(this.conversationIdByRoute, this.replyType);
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
    emitter.on(BUS_EVENTS.INSERT_INTO_NORMAL_EDITOR, this.addIntoEditor);
    emitter.on(CMD_AI_ASSIST, this.executeCopilotAction);
  },
  unmounted() {
    clearTimeout(this.groupMentionFetchTimeout);
    document.removeEventListener('paste', this.onPaste);
    document.removeEventListener('keydown', this.handleKeyEvents);
    emitter.off(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.onReplyToMessage);
    emitter.off(BUS_EVENTS.INSERT_INTO_NORMAL_EDITOR, this.addIntoEditor);
    emitter.off(
      BUS_EVENTS.NEW_CONVERSATION_MODAL,
      this.onNewConversationModalActive
    );
    emitter.off(CMD_AI_ASSIST, this.executeCopilotAction);
  },
  methods: {
    groupMentionSearchTerm(message = this.message) {
      const match = message.match(/(?:^|\s)@([^\s@]*)$/);
      return match ? match[1] : '';
    },
    debouncedFetchGroupMentionContacts() {
      clearTimeout(this.groupMentionFetchTimeout);
      this.groupMentionFetchTimeout = setTimeout(() => {
        this.fetchGroupMentionContacts(this.groupMentionSearchTerm());
      }, 250);
    },
    async fetchGroupMentionContacts(query = '') {
      const normalizedQuery = query.trim();
      if (normalizedQuery.length < 2) {
        this.groupMentionContacts = [];
        return;
      }

      if (!this.canUseGroupMentions || this.isLoadingGroupMentionContacts) {
        this.groupMentionContacts = [];
        return;
      }

      this.isLoadingGroupMentionContacts = true;
      try {
        const { data } = await conversationApi.fetchGroupContacts(
          this.currentChat.id,
          1,
          normalizedQuery
        );
        this.groupMentionContacts = (data.payload || [])
          .map(member => this.normalizeGroupMentionContact(member))
          .filter(contact => contact.id && contact.bsuid);
      } finally {
        this.isLoadingGroupMentionContacts = false;
      }
    },
    normalizeGroupMentionContact(member = {}) {
      const contact = member.contact || {};
      const metadata = member.metadata || {};
      const phoneNumber =
        contact.phone_number?.replace(/\D/g, '') ||
        metadata.wa_id?.replace(/\D/g, '') ||
        (!member.participant_identifier?.includes('@')
          ? member.participant_identifier?.replace(/\D/g, '')
          : '');
      const bsuid =
        contact.bsuid ||
        metadata.user_id ||
        metadata.lid ||
        (metadata.jid?.endsWith('@lid') ? metadata.jid : '') ||
        phoneNumber;
      const name =
        contact.name ||
        contact.whatsapp_username ||
        metadata.name ||
        member.participant_identifier ||
        bsuid;

      return {
        id: contact.id,
        bsuid,
        name,
        displayName: name,
        whatsapp_username: contact.whatsapp_username,
        phone_number: contact.phone_number,
        thumbnail: contact.thumbnail,
      };
    },
    groupMentionAttributesFor(message = '') {
      if (!this.canUseGroupMentions || !message) return [];

      const mentionsByContactId = new Map(
        this.groupMentionContacts.map(contact => [
          contact.id?.toString(),
          contact,
        ])
      );

      return Array.from(message.matchAll(GROUP_CONTACT_MENTION_REGEX)).flatMap(
        match => {
          const contactId = match[2] || match[4];
          const mentionName = match[3] || match[5] || match[1];
          const contact = mentionsByContactId.get(contactId);
          if (!contact?.bsuid) return [];

          return {
            contact_id: contact.id,
            name: decodeURIComponent(mentionName || ''),
            bsuid: contact.bsuid,
          };
        }
      );
    },
    withGroupMentionsInPayload(payload, message = payload.message) {
      const groupMentions = this.groupMentionAttributesFor(message);
      if (!groupMentions.length) return payload;

      return {
        ...payload,
        contentAttributes: {
          ...(payload.contentAttributes || {}),
          group_mentions: groupMentions,
        },
      };
    },
    getDraftKey(
      conversationId = this.conversationIdByRoute,
      replyType = this.replyType
    ) {
      return `draft-${conversationId}-${replyType}`;
    },
    getCopilotAcceptedMessage(replyType = this.replyType) {
      const key = this.getDraftKey(this.conversationIdByRoute, replyType);
      return this.copilotAcceptedMessages[key] || '';
    },
    setCopilotAcceptedMessage(message, replyType = this.replyType) {
      const key = this.getDraftKey(this.conversationIdByRoute, replyType);
      this.copilotAcceptedMessages[key] = trimContent(
        message || '',
        this.maxLength
      );
    },
    clearCopilotAcceptedMessage(replyType = this.replyType) {
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
    toggleQuotedReply() {
      if (!this.isAnEmailChannel) {
        return;
      }

      const nextValue = !this.quotedReplyPreference;
      this.setQuotedReplyFlagForInbox(this.channelType, nextValue);
    },
    shouldIncludeQuotedEmail() {
      return (
        this.isQuotedEmailReplyEnabled &&
        this.quotedReplyPreference &&
        this.shouldShowQuotedReplyToggle &&
        !!this.quotedEmailText
      );
    },
    getMessageWithQuotedEmailText(message) {
      if (!this.shouldIncludeQuotedEmail()) {
        return message;
      }

      const quotedText = this.quotedEmailText || '';
      const header = buildQuotedEmailHeader(
        this.lastEmailWithQuotedContent,
        this.currentContact,
        this.inbox
      );

      return appendQuotedTextToMessage(message, quotedText, header);
    },
    resetRecorderAndClearAttachments() {
      // Reset audio recorder UI state
      this.resetAudioRecorderInput();
      // Reset attached files
      this.attachedFiles = [];
      this.attachedContacts = [];
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
    getFromDraft() {
      if (this.conversationIdByRoute) {
        const key = this.getDraftKey();
        const messageFromStore =
          this.$store.getters['draftMessages/get'](key) || '';

        // ensure that the message has signature set based on the ui setting
        this.message = this.toggleSignatureForDraft(messageFromStore);
      }
    },
    toggleSignatureForDraft(message) {
      // Even when editor is disabled (e.g. WhatsApp/API can't reply), we must
      // still normalize stale signatures out of drafts when signature is off.
      if (this.isEditorDisabled && this.sendWithSignature) {
        return message;
      }

      const effectiveChannelType = getEffectiveChannelType(
        this.channelType,
        this.inbox?.medium || ''
      );
      return this.sendWithSignature
        ? appendSignature(message, this.messageSignature, effectiveChannelType)
        : removeSignature(message, this.messageSignature, effectiveChannelType);
    },
    removeFromDraft() {
      if (this.conversationIdByRoute) {
        const key = this.getDraftKey();
        this.$store.dispatch('draftMessages/delete', { key });
      }
    },
    getElementToBind() {
      return this.replyEditor;
    },
    getKeyboardEvents() {
      return {
        Escape: {
          action: () => {
            this.hideEmojiPicker();
          },
          allowOnFocusedInput: true,
        },
        '$mod+KeyK': {
          action: e => {
            e.preventDefault();
            const ninja = document.querySelector('ninja-keys');
            ninja.open();
          },
          allowOnFocusedInput: true,
        },
        Enter: {
          action: e => {
            if (this.isAValidEvent('enter')) {
              this.onSendReply();
              e.preventDefault();
            }
          },
          allowOnFocusedInput: true,
        },
        '$mod+Enter': {
          action: () => {
            if (this.copilot.isActive.value && this.isFocused) {
              this.onSubmitCopilotReply();
            } else if (this.isAValidEvent('cmd_enter')) {
              this.onSendReply();
            }
          },
          allowOnFocusedInput: true,
        },
      };
    },
    isAValidEvent(selectedKey) {
      return (
        !this.showUserMentions &&
        !this.showGroupMentions &&
        !this.showMentions &&
        !this.showCannedMenu &&
        !this.showVariablesMenu &&
        this.isFocused &&
        this.isEditorHotKeyEnabled(selectedKey)
      );
    },
    onPaste(e) {
      // Don't handle paste if compose new conversation modal is open
      if (this.newConversationModalActive) return;

      // Don't handle paste if editor is disabled
      if (this.isEditorDisabled) return;
      if (!this.showFileUpload && !this.isOnPrivateNote) return;

      // Filter valid files (non-zero size)
      Array.from(e.clipboardData.files)
        .filter(file => file.size > 0)
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
          this.onFileUpload({ name, type, size, file });
        });
    },
    toggleUserMention(currentMentionState) {
      this.showUserMentions = currentMentionState;
    },
    toggleGroupMention(currentMentionState) {
      this.showGroupMentions = currentMentionState;
    },
    toggleCannedMenu(value) {
      this.showCannedMenu = value;
    },
    toggleVariablesMenu(value) {
      this.showVariablesMenu = value;
    },
    openWhatsappTemplateModal() {
      this.showWhatsAppTemplatesModal = true;
    },
    hideWhatsappTemplatesModal() {
      this.showWhatsAppTemplatesModal = false;
    },
    openContentTemplateModal() {
      this.showContentTemplatesModal = true;
    },
    hideContentTemplatesModal() {
      this.showContentTemplatesModal = false;
    },
    openContactAttachmentModal() {
      this.showContactAttachmentModal = true;
    },
    hideContactAttachmentModal() {
      this.showContactAttachmentModal = false;
    },
    setAttachedContacts(contacts) {
      this.attachedContacts = contacts;
      this.hideContactAttachmentModal();
    },
    removeAttachedContact(contactId) {
      this.attachedContacts = this.attachedContacts.filter(
        contact => contact.id !== contactId
      );
    },
    showStickerPickerModal() {
      // eslint-disable-next-line no-console
      console.info('[StickerPicker] open modal', {
        conversationId: this.currentChat?.id,
        inboxId: this.inboxId,
      });
      this.showStickerPicker = true;
    },
    hideStickerPickerModal() {
      // eslint-disable-next-line no-console
      console.info('[StickerPicker] close modal');
      this.showStickerPicker = false;
    },
    sendStickerMessage(sticker) {
      // eslint-disable-next-line no-console
      console.info('[StickerPicker] send message', {
        conversationId: this.currentChat.id,
        stickerId: sticker.id,
      });
      this.sendMessage({
        conversationId: this.currentChat.id,
        content_type: 'sticker',
        content_attributes: {
          sticker_id: sticker.id,
          sticker_url: sticker.file_url,
        },
      });
    },
    confirmOnSendReply() {
      if (this.isReplyButtonDisabled) {
        return;
      }
      if (!this.showMentions) {
        const copilotAcceptedMessage = this.getCopilotAcceptedMessage();
        const isOnWhatsApp =
          this.isATwilioWhatsAppChannel ||
          this.isAWhatsAppCloudChannel ||
          this.isAUnoapiChannel ||
          this.is360DialogWhatsAppChannel;
        // When users send messages containing both text and attachments on Instagram, Instagram treats them as separate messages.
        // Although ViperChat combines these into a single message, Instagram sends separate echo events for each component.
        // This can create duplicate messages in ViperChat. To prevent this issue, we'll handle text and attachments as separate messages.
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
        }

        this.clearMessage();
        this.hideEmojiPicker();
        this.$emit('update:popOutReplyBox', false);
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
      const normalizeForComparison = message => {
        let normalizedMessage = message || '';

        if (this.sendWithSignature && this.messageSignature && !isPrivate) {
          const effectiveChannelType = getEffectiveChannelType(
            this.channelType,
            this.inbox?.medium || ''
          );
          normalizedMessage = removeSignature(
            normalizedMessage,
            this.messageSignature,
            effectiveChannelType
          );
        }

        return trimContent(normalizedMessage);
      };

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
    setReplyMode(mode = REPLY_EDITOR_MODES.REPLY) {
      // Clear attachments when switching between private note and reply modes
      // This is to prevent from breaking the upload rules
      if (this.attachedFiles.length > 0) this.attachedFiles = [];
      if (this.attachedContacts.length > 0) this.attachedContacts = [];

      const { can_reply: canReply } = this.currentChat;
      this.$store.dispatch('draftMessages/setReplyEditorMode', {
        mode,
      });
      if (canReply || this.isAWhatsAppChannel || this.isAPIInbox)
        this.replyType = mode;
      if (this.isRecordingAudio) {
        this.toggleAudioRecorder();
      }
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
      this.message = '';
      this.clearCopilotAcceptedMessage();
      if (this.sendWithSignature && !this.isPrivate) {
        // if signature is enabled, append it to the message
        const effectiveChannelType = getEffectiveChannelType(
          this.channelType,
          this.inbox?.medium || ''
        );
        this.message = appendSignature(
          this.message,
          this.messageSignature,
          effectiveChannelType
        );
      }
      this.attachedFiles = [];
      this.attachedContacts = [];
      this.isRecordingAudio = false;
      this.resetReplyToMessage();
      this.resetAudioRecorderInput();
    },
    openScheduleModal() {
      this.showScheduledMessageModal = true;
    },
    onScheduledMessageCreated() {
      this.clearMessage();
      this.showScheduledMessageModal = false;
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
      }
    },
    toggleAudioRecorderPlayPause() {
      if (!this.$refs.audioRecorderInput) return;
      if (!this.recordingAudioState) {
        this.$refs.audioRecorderInput.stopRecording();
      } else {
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
    onTypingOff() {
      this.toggleTyping('off');
    },
    onBlur() {
      this.isFocused = false;
      this.saveDraft(this.conversationIdByRoute, this.replyType);
    },
    onFocus() {
      this.isFocused = true;
    },
    onRecordProgressChanged(duration) {
      this.recordingAudioDurationText = duration;
    },
    onFinishRecorder(file) {
      this.recordingAudioState = 'stopped';
      this.hasRecordedAudio = true;
      // Added a new key isRecordedAudio to the file to find it's and recorded audio
      // Because to filter and show only non recorded audio and other attachments
      const autoRecordedFile = {
        ...file,
        isRecordedAudio: true,
      };
      return file && this.onFileUpload(autoRecordedFile);
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
    attachFile({ blob, file }) {
      if (!this.showFileUpload && !this.isOnPrivateNote) return;

      if (!this.enableMultipleFileUpload && this.attachedFiles.length > 0) {
        useAlert(this.$t('CONVERSATION.REPLYBOX.TIP_ATTACH_SINGLE'));
        return;
      }
      const reader = new FileReader();
      reader.readAsDataURL(file.file);
      reader.onloadend = () => {
        this.attachedFiles.push({
          currentChatId: this.currentChat.id,
          resource: blob || file,
          isPrivate: this.isPrivate,
          thumb: reader.result,
          blobSignedId: blob ? blob.signed_id : undefined,
          isRecordedAudio: file?.isRecordedAudio || false,
        });
      };
    },
    removeAttachment(attachments) {
      this.attachedFiles = attachments;
    },
    serializeAttachedContact(contact) {
      const fullName =
        contact.formattedName ||
        contact.name ||
        [contact.firstName, contact.lastName].filter(Boolean).join(' ') ||
        '';
      const [firstName, ...lastNameParts] = fullName.split(' ').filter(Boolean);

      return {
        id: contact.id,
        formatted_name: fullName,
        first_name: firstName || fullName,
        last_name: lastNameParts.join(' ') || '',
        phone_number: contact.phoneNumber || contact.phone_number || '',
        email: contact.email || '',
      };
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

      if (this.attachedContacts.length) {
        let contactsPayload = {
          conversationId: this.currentChat.id,
          private: false,
          sender: this.sender,
          contentType: 'text',
          contentAttributes: {
            contacts: this.attachedContacts.map(contact =>
              this.serializeAttachedContact(contact)
            ),
          },
        };

        contactsPayload = this.setReplyToInPayload(contactsPayload);
        contactsPayload = this.withGroupMentionsInPayload(
          contactsPayload,
          contactsPayload.message
        );
        multipleMessagePayload.push(contactsPayload);
      }

      if (this.attachedFiles && this.attachedFiles.length) {
        let caption =
          this.isAnInstagramChannel || this.isATiktokChannel ? '' : message;
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
          };

          attachmentPayload = this.setReplyToInPayload(attachmentPayload);
          attachmentPayload = this.withGroupMentionsInPayload(
            attachmentPayload,
            attachmentPayload.message
          );
          multipleMessagePayload.push(attachmentPayload);
          // For WhatsApp, only the first attachment gets a caption
          if (!this.isAnInstagramChannel) caption = '';
        });
      }

      const hasNoAttachments =
        !this.attachedFiles || !this.attachedFiles.length;
      // For Instagram and TikTok, text must always be sent as a separate message (no captions on attachments).
      // For WhatsApp, text is sent separately only when there are no file attachments.
      if (
        ((this.isAnInstagramChannel || this.isATiktokChannel) && message) ||
        (!(this.isAnInstagramChannel || this.isATiktokChannel) &&
          hasNoAttachments &&
          message)
      ) {
        let messagePayload = {
          conversationId: this.currentChat.id,
          message,
          private: false,
          sender: this.sender,
        };

        messagePayload = this.setReplyToInPayload(messagePayload);
        messagePayload = this.withGroupMentionsInPayload(
          messagePayload,
          messagePayload.message
        );

        multipleMessagePayload.push(messagePayload);
      }

      return multipleMessagePayload;
    },
    getMessagePayload(message) {
      const messageWithQuote = this.getMessageWithQuotedEmailText(message);

      let messagePayload = {
        conversationId: this.currentChat.id,
        message: messageWithQuote,
        private: this.isPrivate,
        sender: this.sender,
      };
      messagePayload = this.setReplyToInPayload(messagePayload);
      messagePayload = this.withGroupMentionsInPayload(
        messagePayload,
        messageWithQuote
      );

      if (this.attachedFiles && this.attachedFiles.length) {
        messagePayload.files = [];
        this.attachedFiles.forEach(attachment => {
          if (this.globalConfig.directUploadsEnabled) {
            messagePayload.files.push(attachment.blobSignedId);
          } else {
            messagePayload.files.push(attachment.resource.file);
          }
        });
      }

      if (this.attachedContacts.length) {
        messagePayload.contentType = 'text';
        messagePayload.contentAttributes = {
          ...(messagePayload.contentAttributes || {}),
          contacts: this.attachedContacts.map(contact =>
            this.serializeAttachedContact(contact)
          ),
        };
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

      this.inReplyTo = this.currentChat?.messages?.find(message => {
        if (message.id === replyToMessageId) {
          return true;
        }
        return false;
      });
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
      this.hasRecordedAudio = false;
      // Only clear the recorded audio when we click toggle button.
      this.attachedFiles = this.attachedFiles.filter(
        file => !file?.isRecordedAudio
      );
    },
    togglePopout() {
      this.$emit('update:popOutReplyBox', !this.popOutReplyBox);
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
  },
};
</script>

<template>
  <ReplyBoxBanner :message="message" :is-on-private-note="isOnPrivateNote" />
  <div ref="replyEditor" class="reply-box" :class="replyBoxClass">
    <ReplyTopPanel
      :mode="replyType"
      :conversation-id="conversationId"
      :is-reply-restricted="isReplyRestricted"
      :disabled="
        (copilot.isActive.value && copilot.isButtonDisabled.value) ||
        showAudioRecorderEditor
      "
      :is-editor-disabled="isEditorDisabled"
      :is-message-length-reaching-threshold="isMessageLengthReachingThreshold"
      :characters-remaining="charactersRemaining"
      :editor-content="message"
      :popout-reply-box="popOutReplyBox"
      @set-reply-mode="setReplyMode"
      @toggle-editor-size="toggleEditorSize"
      @toggle-popout="togglePopout"
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
        <EmojiInput
          v-if="showEmojiPicker"
          v-on-clickaway="hideEmojiPicker"
          :class="{
            'emoji-dialog--expanded': isOnExpandedLayout || popOutReplyBox,
          }"
          :on-click="addIntoEditor"
        />
        <ReplyEmailHead
          v-if="showReplyHead && isDefaultEditorMode"
          v-model:cc-emails="ccEmails"
          v-model:bcc-emails="bccEmails"
          v-model:to-emails="toEmails"
        />
        <AudioRecorder
          v-if="showAudioRecorderEditor"
          ref="audioRecorderInput"
          :audio-record-format="audioRecordFormat"
          @recorder-progress-changed="onRecordProgressChanged"
          @finish-record="onFinishRecorder"
          @play="recordingAudioState = 'playing'"
          @pause="recordingAudioState = 'paused'"
        />
        <CopilotEditorSection
          v-if="copilot.isActive.value && !showAudioRecorderEditor"
          :show-copilot-editor="copilot.showEditor.value"
          :is-generating-content="copilot.isGenerating.value"
          :generated-content="copilot.generatedContent.value"
          :is-popout="popOutReplyBox"
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
          class="input popover-prosemirror-menu"
          :is-private="isOnPrivateNote"
          :placeholder="messagePlaceHolder"
          :update-selection-with="updateEditorSelectionWith"
          :min-height="4"
          :disabled="isEditorDisabled"
          enable-variables
          :variables="messageVariables"
          :signature="messageSignature"
          allow-signature
          :enable-group-mentions="canUseGroupMentions"
          :group-mention-contacts="groupMentionContacts"
          :channel-type="channelType"
          :medium="inbox.medium"
          @typing-off="onTypingOff"
          @typing-on="onTypingOn"
          @focus="onFocus"
          @blur="onBlur"
          @toggle-user-mention="toggleUserMention"
          @toggle-group-mention="toggleGroupMention"
          @toggle-canned-menu="toggleCannedMenu"
          @toggle-variables-menu="toggleVariablesMenu"
          @clear-selection="clearEditorSelection"
          @execute-copilot-action="executeCopilotAction"
        />

        <QuotedEmailPreview
          v-if="shouldShowQuotedPreview && isDefaultEditorMode"
          :quoted-email-text="quotedEmailText"
          :preview-text="quotedEmailPreviewText"
          class="mb-2"
          @toggle="toggleQuotedReply"
        />

        <div
          v-if="(hasAttachedContacts || hasAttachments) && isDefaultEditorMode"
          class="bg-transparent py-0 mb-2"
          @paste="onPaste"
        >
          <AttachedContactsPreview
            v-if="hasAttachedContacts"
            :contacts="attachedContacts"
            @remove="removeAttachedContact"
          />
          <AttachmentPreview
            v-if="hasAttachments"
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
        :on-file-upload="onFileUpload"
        :on-send="onSendReply"
        :conversation-type="conversationType"
        :recording-audio-duration-text="recordingAudioDurationText"
        :recording-audio-state="recordingAudioState"
        :send-button-text="replyButtonLabel"
        :show-audio-recorder="showAudioRecorder"
        :show-emoji-picker="showEmojiPicker"
        :show-file-upload="showFileUpload"
        :show-quoted-reply-toggle="shouldShowQuotedReplyToggle"
        :quoted-reply-enabled="quotedReplyPreference"
        :toggle-audio-recorder-play-pause="toggleAudioRecorderPlayPause"
        :toggle-audio-recorder="toggleAudioRecorder"
        :toggle-emoji-picker="toggleEmojiPicker"
        :message="message"
        :portal-slug="connectedPortalSlug"
        :new-conversation-modal-active="newConversationModalActive"
        :show-schedule-options="true"
        @open-contact-picker="openContactAttachmentModal"
        @toggle-sticker-picker="showStickerPickerModal"
        @select-whatsapp-template="openWhatsappTemplateModal"
        @select-content-template="openContentTemplateModal"
        @toggle-insert-article="toggleInsertArticle"
        @toggle-quoted-reply="toggleQuotedReply"
        @schedule-message="openScheduleModal"
      />
    </Transition>
    <WhatsappTemplates
      :inbox-id="inbox.id"
      :show="showWhatsAppTemplatesModal"
      @close="hideWhatsappTemplatesModal"
      @on-send="onSendWhatsAppReply"
      @cancel="hideWhatsappTemplatesModal"
    />

    <StickerPickerDialog
      v-if="showStickerPicker"
      :show="showStickerPicker"
      :inbox-id="inboxId"
      @close="hideStickerPickerModal"
      @send="sendStickerMessage"
    />

    <ContentTemplates
      :inbox-id="inbox.id"
      :show="showContentTemplatesModal"
      @close="hideContentTemplatesModal"
      @on-send="onSendContentTemplateReply"
      @cancel="hideContentTemplatesModal"
    />

    <ContactAttachmentModal
      v-model:show="showContactAttachmentModal"
      :selected-contacts="attachedContacts"
      @close="hideContactAttachmentModal"
      @attach="setAttachedContacts"
    />

    <ScheduledMessageModal
      v-if="showScheduledMessageModal"
      :show="showScheduledMessageModal"
      :conversation-id="conversationId"
      :inbox-id="inbox.id"
      :initial-content="message"
      :initial-attachment="attachedFiles[0]"
      @update:show="val => showScheduledMessageModal = val"
      @close="showScheduledMessageModal = false"
      @scheduledMessageCreated="onScheduledMessageCreated"
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
