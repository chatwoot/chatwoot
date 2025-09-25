<script>
import { defineAsyncComponent, useTemplateRef } from 'vue';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useTrack } from 'dashboard/composables';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';

import CannedResponse from './CannedResponse.vue';
import ReplyToMessage from './ReplyToMessage.vue';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';
import AttachmentPreview from 'dashboard/components/widgets/AttachmentsPreview.vue';
import ReplyTopPanel from 'dashboard/components/widgets/WootWriter/ReplyTopPanel.vue';
import ReplyEmailHead from './ReplyEmailHead.vue';
import ReplyBottomPanel from 'dashboard/components/widgets/WootWriter/ReplyBottomPanel.vue';
import ArticleSearchPopover from 'dashboard/routes/dashboard/helpcenter/components/ArticleSearch/SearchPopover.vue';
import MessageSignatureMissingAlert from './MessageSignatureMissingAlert.vue';
import Banner from 'dashboard/components/ui/Banner.vue';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import AudioRecorder from 'dashboard/components/widgets/WootWriter/AudioRecorder.vue';
import { AUDIO_FORMATS } from 'shared/constants/messages';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import {
  getMessageVariables,
  getUndefinedVariablesInMessage,
  replaceVariablesInMessage,
} from '@chatwoot/utils';
import WhatsappTemplates from './WhatsappTemplates/Modal.vue';
import { MESSAGE_MAX_LENGTH } from 'shared/helpers/MessageTypeHelper';
import inboxMixin, { INBOX_FEATURES } from 'shared/mixins/inboxMixin';
import { trimContent, debounce, getRecipients } from '@chatwoot/utils';
import wootConstants from 'dashboard/constants/globals';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import {
  appendSignature,
  removeSignature,
  replaceSignature,
  extractTextFromMarkdown,
} from 'dashboard/helper/editorHelper';
import AppleRichLinkPreview from './AppleRichLinkPreview.vue';
import {
  URL_REGEX,
  normalizeURL,
  detectURLsInText,
  splitMessageByURLs,
  processMessageForAppleMessages,
} from 'dashboard/helper/appleMessagesRichLink';

import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import { emitter } from 'shared/helpers/mitt';
const EmojiInput = defineAsyncComponent(
  () => import('shared/components/emoji/EmojiInput.vue')
);

export default {
  components: {
    AppleRichLinkPreview,
    ArticleSearchPopover,
    AttachmentPreview,
    AudioRecorder,
    Banner,
    CannedResponse,
    EmojiInput,
    MessageSignatureMissingAlert,
    ReplyBottomPanel,
    ReplyEmailHead,
    ReplyToMessage,
    ReplyTopPanel,
    ResizableTextArea,
    WhatsappTemplates,
    WootMessageEditor,
  },
  mixins: [inboxMixin, fileUploadMixin, keyboardEventListenerMixins],
  props: {
    popOutReplyBox: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['update:popOutReplyBox'],
  setup() {
    const {
      uiSettings,
      updateUISettings,
      isEditorHotKeyEnabled,
      fetchSignatureFlagFromUISettings,
    } = useUISettings();

    const replyEditor = useTemplateRef('replyEditor');

    return {
      uiSettings,
      updateUISettings,
      isEditorHotKeyEnabled,
      fetchSignatureFlagFromUISettings,
      replyEditor,
    };
  },
  data() {
    return {
      message: '',
      inReplyTo: {},
      isFocused: false,
      showEmojiPicker: false,
      attachedFiles: [],
      isRecordingAudio: false,
      recordingAudioState: '',
      recordingAudioDurationText: '',
      isUploading: false,
      replyType: REPLY_EDITOR_MODES.REPLY,
      mentionSearchKey: '',
      hasSlashCommand: false,
      bccEmails: '',
      ccEmails: '',
      toEmails: '',
      doAutoSaveDraft: () => {},
      showWhatsAppTemplatesModal: false,
      updateEditorSelectionWith: '',
      undefinedVariableMessage: '',
      showMentions: false,
      showUserMentions: false,
      showCannedMenu: false,
      showVariablesMenu: false,
      newConversationModalActive: false,
      showArticleSearchPopover: false,
      hasRecordedAudio: false,
      // Rich Link preview
      richLinkPreviewUrl: '',
      showRichLinkPreview: false,
      richLinkDetectionTimeout: null,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
      messageSignature: 'getMessageSignature',
      currentUser: 'getCurrentUser',
      lastEmail: 'getLastEmailInSelectedChat',
      globalConfig: 'globalConfig/get',
    }),
    currentContact() {
      return this.$store.getters['contacts/getContact'](
        this.currentChat.meta.sender.id
      );
    },
    shouldShowReplyToMessage() {
      return (
        this.inReplyTo?.id &&
        !this.isPrivate &&
        this.inboxHasFeature(INBOX_FEATURES.REPLY_TO) &&
        !this.is360DialogWhatsAppChannel
      );
    },
    showRichContentEditor() {
      if (this.isOnPrivateNote || this.isRichEditorEnabled) {
        return true;
      }

      if (this.isAPIInbox) {
        const {
          display_rich_content_editor: displayRichContentEditor = false,
        } = this.uiSettings;
        return displayRichContentEditor;
      }

      return false;
    },
    assignedAgent: {
      get() {
        return this.currentChat.meta.assignee;
      },
      set(agent) {
        const agentId = agent ? agent.id : 0;
        this.$store.dispatch('setCurrentChatAssignee', agent);
        this.$store
          .dispatch('assignAgent', {
            conversationId: this.currentChat.id,
            agentId,
          })
          .then(() => {
            useAlert(this.$t('CONVERSATION.CHANGE_AGENT'));
          });
      },
    },
    showSelfAssignBanner() {
      if (this.message !== '' && !this.isOnPrivateNote) {
        if (!this.assignedAgent) {
          return true;
        }
        if (this.assignedAgent.id !== this.currentUser.id) {
          return true;
        }
      }

      return false;
    },
    showWhatsappTemplates() {
      return this.isAWhatsAppCloudChannel && !this.isPrivate;
    },
    isPrivate() {
      if (this.currentChat.can_reply || this.isAWhatsAppChannel) {
        return this.isOnPrivateNote;
      }
      return true;
    },
    inboxId() {
      return this.currentChat.inbox_id;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.inboxId);
    },
    isAppleMessagesConversation() {
      return this.inbox?.channel_type === 'Channel::AppleMessagesForBusiness';
    },
    messagePlaceHolder() {
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
        this.isAnAppleMessagesForBusinessChannel
      );
    },
    replyButtonLabel() {
      let sendMessageText = this.$t('CONVERSATION.REPLYBOX.SEND');
      if (this.isPrivate) {
        sendMessageText = this.$t('CONVERSATION.REPLYBOX.CREATE');
      }
      const keyLabel = this.isEditorHotKeyEnabled('cmd_enter')
        ? '(⌘ + ↵)'
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
    isRichEditorEnabled() {
      return this.isAWebWidgetInbox || this.isAnEmailChannel;
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
    isSignatureAvailable() {
      return !!this.signatureToApply;
    },
    sendWithSignature() {
      return this.fetchSignatureFlagFromUISettings(this.channelType);
    },
    editorMessageKey() {
      const { editor_message_key: isEnabled } = this.uiSettings;
      return isEnabled;
    },
    commandPlusEnterToSendEnabled() {
      return this.editorMessageKey === 'cmd_enter';
    },
    enterToSendEnabled() {
      return this.editorMessageKey === 'enter';
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
      if (this.isAWhatsAppChannel || this.isATelegramChannel) {
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
    // ensure that the signature is plain text depending on `showRichContentEditor`
    signatureToApply() {
      return this.showRichContentEditor
        ? this.messageSignature
        : extractTextFromMarkdown(this.messageSignature);
    },
    connectedPortalSlug() {
      const { help_center: portal = {} } = this.inbox;
      const { slug = '' } = portal;
      return slug;
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
      }

      if (this.isOnPrivateNote) {
        return;
      }

      if (canReply || this.isAWhatsAppChannel) {
        this.replyType = REPLY_EDITOR_MODES.REPLY;
      } else {
        this.replyType = REPLY_EDITOR_MODES.NOTE;
      }

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
        this.setToDraft(oldConversationId, this.replyType);
        this.getFromDraft();
        this.resetRecorderAndClearAttachments();
      }
    },
    message(updatedMessage) {
      // Check if the message starts with a slash.
      const bodyWithoutSignature = removeSignature(
        updatedMessage,
        this.signatureToApply
      );
      const startsWithSlash = bodyWithoutSignature.startsWith('/');

      // Determine if the user is potentially typing a slash command.
      // This is true if the message starts with a slash and the rich content editor is not active.
      this.hasSlashCommand = startsWithSlash && !this.showRichContentEditor;
      this.showMentions = this.hasSlashCommand;

      // If a slash command is active, extract the command text after the slash.
      // If not, reset the mentionSearchKey.
      this.mentionSearchKey = this.hasSlashCommand
        ? bodyWithoutSignature.substring(1)
        : '';

      // Check for URLs in Apple Messages conversations
      this.checkForURLsInMessage(updatedMessage);

      // Autosave the current message draft.
      this.doAutoSaveDraft();
    },
    replyType(updatedReplyType, oldReplyType) {
      this.setToDraft(this.conversationIdByRoute, oldReplyType);
      this.getFromDraft();
    },
  },

  mounted() {
    this.getFromDraft();
    // Don't use the keyboard listener mixin here as the events here are supposed to be
    // working even if input/textarea is focussed.
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
    emitter.on(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.fetchAndSetReplyTo);

    // A hacky fix to solve the drag and drop
    // Is showing on top of new conversation modal drag and drop
    // TODO need to find a better solution
    emitter.on(
      BUS_EVENTS.NEW_CONVERSATION_MODAL,
      this.onNewConversationModalActive
    );
    emitter.on(BUS_EVENTS.INSERT_INTO_NORMAL_EDITOR, this.addIntoEditor);
  },
  unmounted() {
    document.removeEventListener('paste', this.onPaste);
    document.removeEventListener('keydown', this.handleKeyEvents);
    emitter.off(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.fetchAndSetReplyTo);
    emitter.off(BUS_EVENTS.INSERT_INTO_NORMAL_EDITOR, this.addIntoEditor);
    emitter.off(
      BUS_EVENTS.NEW_CONVERSATION_MODAL,
      this.onNewConversationModalActive
    );
  },
  methods: {
    handleInsert(article) {
      const { url, title } = article;
      if (this.isRichEditorEnabled) {
        // Removing empty lines from the title
        const lines = title.split('\n');
        const nonEmptyLines = lines.filter(line => line.trim() !== '');
        const filteredMarkdown = nonEmptyLines.join(' ');
        emitter.emit(
          BUS_EVENTS.INSERT_INTO_RICH_EDITOR,
          `[${filteredMarkdown}](${url})`
        );
      } else {
        this.addIntoEditor(
          `${this.$t('CONVERSATION.REPLYBOX.INSERT_READ_MORE')} ${url}`
        );
      }

      useTrack(CONVERSATION_EVENTS.INSERT_ARTICLE_LINK);
    },
    toggleRichContentEditor() {
      this.updateUISettings({
        display_rich_content_editor: !this.showRichContentEditor,
      });

      const plainTextSignature = extractTextFromMarkdown(this.messageSignature);

      if (!this.showRichContentEditor && this.messageSignature) {
        // remove the old signature -> extract text from markdown -> attach new signature
        let message = removeSignature(this.message, this.messageSignature);
        message = extractTextFromMarkdown(message);
        message = appendSignature(message, plainTextSignature);

        this.message = message;
      } else {
        this.message = replaceSignature(
          this.message,
          plainTextSignature,
          this.messageSignature
        );
      }
    },
    resetRecorderAndClearAttachments() {
      // Reset audio recorder UI state
      this.resetAudioRecorderInput();
      // Reset attached files
      this.attachedFiles = [];
    },
    saveDraft(conversationId, replyType) {
      if (this.message || this.message === '') {
        const key = `draft-${conversationId}-${replyType}`;
        const draftToSave = trimContent(this.message || '');

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
        const key = `draft-${this.conversationIdByRoute}-${this.replyType}`;
        const messageFromStore =
          this.$store.getters['draftMessages/get'](key) || '';

        // ensure that the message has signature set based on the ui setting
        this.message = this.toggleSignatureForDraft(messageFromStore);
      }
    },
    toggleSignatureForDraft(message) {
      if (this.isPrivate) {
        return message;
      }

      return this.sendWithSignature
        ? appendSignature(message, this.signatureToApply)
        : removeSignature(message, this.signatureToApply);
    },
    removeFromDraft() {
      if (this.conversationIdByRoute) {
        const key = `draft-${this.conversationIdByRoute}-${this.replyType}`;
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
            this.hideMentions();
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
            if (this.isAValidEvent('cmd_enter')) {
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
        !this.showMentions &&
        !this.showCannedMenu &&
        !this.showVariablesMenu &&
        this.isFocused &&
        this.isEditorHotKeyEnabled(selectedKey)
      );
    },
    onPaste(e) {
      const data = e.clipboardData.files;
      if (!this.showRichContentEditor && data.length !== 0) {
        this.$refs.messageInput.$el.blur();
      }
      if (!data.length || !data[0]) {
        return;
      }
      data.forEach(file => {
        const { name, type, size } = file;
        this.onFileUpload({ name, type, size, file: file });
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
    openWhatsappTemplateModal() {
      this.showWhatsAppTemplatesModal = true;
    },
    hideWhatsappTemplatesModal() {
      this.showWhatsAppTemplatesModal = false;
    },
    onClickSelfAssign() {
      const {
        account_id,
        availability_status,
        available_name,
        email,
        id,
        name,
        role,
        avatar_url,
      } = this.currentUser;
      const selfAssign = {
        account_id,
        availability_status,
        available_name,
        email,
        id,
        name,
        role,
        thumbnail: avatar_url,
      };
      this.assignedAgent = selfAssign;
    },
    confirmOnSendReply() {
      if (this.isReplyButtonDisabled) {
        return;
      }
      if (!this.showMentions) {
        const isOnWhatsApp =
          this.isATwilioWhatsAppChannel ||
          this.isAWhatsAppCloudChannel ||
          this.is360DialogWhatsAppChannel;
        // When users send messages containing both text and attachments on Instagram, Instagram treats them as separate messages.
        // Although Chatwoot combines these into a single message, Instagram sends separate echo events for each component.
        // This can create duplicate messages in Chatwoot. To prevent this issue, we'll handle text and attachments as separate messages.
        const isOnInstagram = this.isAnInstagramChannel;
        if ((isOnWhatsApp || isOnInstagram) && !this.isPrivate) {
          this.sendMessageAsMultipleMessages(this.message);
        } else {
          const messagePayload = this.getMessagePayload(this.message);
          this.sendMessage(messagePayload);
        }

        if (!this.isPrivate) {
          this.clearEmailField();
        }

        this.clearMessage();
        this.hideEmojiPicker();
        this.$emit('update:popOutReplyBox', false);
      }
    },
    sendMessageAsMultipleMessages(message) {
      const messages = this.getMultipleMessagesPayload(message);
      messages.forEach(messagePayload => {
        this.sendMessage(messagePayload);
      });
    },
    sendMessageAnalyticsData(isPrivate) {
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
    async sendMessage(messagePayload) {
      try {
        await this.$store.dispatch(
          'createPendingMessageAndSend',
          messagePayload
        );
        emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        emitter.emit(BUS_EVENTS.MESSAGE_SENT);
        this.removeFromDraft();
        this.sendMessageAnalyticsData(messagePayload.private);
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
    replaceText(message) {
      if (this.sendWithSignature && !this.private) {
        // if signature is enabled, append it to the message
        // appendSignature ensures that the signature is not duplicated
        // so we don't need to check if the signature is already present
        message = appendSignature(message, this.signatureToApply);
      }

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
      const { can_reply: canReply } = this.currentChat;
      this.$store.dispatch('draftMessages/setReplyEditorMode', {
        mode,
      });
      if (canReply || this.isAWhatsAppChannel) this.replyType = mode;
      if (this.showRichContentEditor) {
        if (this.isRecordingAudio) {
          this.toggleAudioRecorder();
        }
        return;
      }
      this.$nextTick(() => this.$refs.messageInput.focus());
    },
    clearEditorSelection() {
      this.updateEditorSelectionWith = '';
    },
    insertIntoTextEditor(text, selectionStart, selectionEnd) {
      const { message } = this;
      const newMessage =
        message.slice(0, selectionStart) +
        text +
        message.slice(selectionEnd, message.length);
      this.message = newMessage;
    },
    addIntoEditor(content) {
      if (this.showRichContentEditor) {
        this.updateEditorSelectionWith = content;
        this.onFocus();
      }
      if (!this.showRichContentEditor) {
        const { selectionStart, selectionEnd } = this.$refs.messageInput.$el;
        this.insertIntoTextEditor(content, selectionStart, selectionEnd);
      }
    },
    clearMessage() {
      this.message = '';
      if (this.sendWithSignature && !this.isPrivate) {
        // if signature is enabled, append it to the message
        this.message = appendSignature(this.message, this.signatureToApply);
      }
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
      this.isRecorderAudioStopped = !this.isRecordingAudio;
      if (!this.isRecordingAudio) {
        this.resetAudioRecorderInput();
      }
    },
    toggleAudioRecorderPlayPause() {
      if (!this.isRecordingAudio) {
        return;
      }
      if (!this.isRecorderAudioStopped) {
        this.isRecorderAudioStopped = true;
        this.$refs.audioRecorderInput.stopRecording();
      } else if (this.isRecorderAudioStopped) {
        this.$refs.audioRecorderInput.playPause();
      }
    },
    hideEmojiPicker() {
      if (this.showEmojiPicker) {
        this.toggleEmojiPicker();
      }
    },
    hideMentions() {
      this.showMentions = false;
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

      if (this.attachedFiles && this.attachedFiles.length) {
        let caption = this.isAnInstagramChannel ? '' : message;
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
          multipleMessagePayload.push(attachmentPayload);
          // For WhatsApp, only the first attachment gets a caption
          if (!this.isAnInstagramChannel) caption = '';
        });
      }

      const hasNoAttachments =
        !this.attachedFiles || !this.attachedFiles.length;
      // For Instagram, we need a separate text message
      // For WhatsApp, we only need a text message if there are no attachments
      if (
        (this.isAnInstagramChannel && this.message) ||
        (!this.isAnInstagramChannel && hasNoAttachments)
      ) {
        let messagePayload = {
          conversationId: this.currentChat.id,
          message,
          private: false,
          sender: this.sender,
        };

        messagePayload = this.setReplyToInPayload(messagePayload);

        multipleMessagePayload.push(messagePayload);
      }

      return multipleMessagePayload;
    },
    getMessagePayload(message) {
      // Normalize URLs in message for Apple Messages conversations
      let processedMessage = message;
      if (this.isAppleMessagesConversation) {
        const detectedURLs = detectURLsInText(message);
        if (detectedURLs.length > 0) {
          // Replace URLs in the message with normalized versions
          const originalUrls = message.match(URL_REGEX) || [];
          detectedURLs.forEach((normalizedUrl, index) => {
            if (originalUrls[index]) {
              processedMessage = processedMessage.replace(
                originalUrls[index],
                normalizedUrl
              );
            }
          });
        }
      }

      let messagePayload = {
        conversationId: this.currentChat.id,
        message: processedMessage,
        private: this.isPrivate,
        sender: this.sender,
      };
      messagePayload = this.setReplyToInPayload(messagePayload);

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
    async sendAppleMessage(messageData) {
      console.log('🔥 ReplyBox: sendAppleMessage called with:', messageData);
      try {
        const messagePayload = {
          conversationId: this.currentChat.id,
          message:
            messageData.content || messageData.summary_text || 'Apple Message',
          content_type: messageData.content_type,
          content_attributes: messageData.content_attributes,
          private: false,
        };

        console.log('🔥 ReplyBox: messagePayload prepared:', messagePayload);
        console.log('🔥 ReplyBox: about to call createPendingMessageAndSend');

        // Use createPendingMessageAndSend directly to ensure proper message creation
        await this.$store.dispatch(
          'createPendingMessageAndSend',
          messagePayload
        );

        console.log(
          '🔥 ReplyBox: createPendingMessageAndSend dispatched successfully'
        );
        this.clearMessage();
        this.hideEmojiPicker();

        // Note: Tracking removed to avoid $track dependency issues

        console.log('🔥 ReplyBox: Apple message sent successfully');
      } catch (error) {
        console.error('🔥 ReplyBox: Error sending Apple message:', error);
        const errorMessage =
          error?.message || this.$t('CONVERSATION.MESSAGE_ERROR');
        this.$store.dispatch('alerts/show', {
          message: errorMessage,
          type: 'error',
        });
      }
    },

    // Rich Link URL detection methods
    checkForURLsInMessage(message) {
      if (!this.isAppleMessagesConversation || !message) {
        this.hideRichLinkPreview();
        return;
      }

      // Clear existing timeout
      if (this.richLinkDetectionTimeout) {
        clearTimeout(this.richLinkDetectionTimeout);
      }

      // Debounce URL detection
      this.richLinkDetectionTimeout = setTimeout(() => {
        // Use the enhanced URL detection from appleMessagesRichLink helper
        const detectedURLs = detectURLsInText(message);

        if (detectedURLs.length > 0) {
          const url = detectedURLs[0]; // Use first detected URL (already normalized)
          // Check if URL should trigger Rich Link preview
          const urlRatio = url.length / message.length;
          if (urlRatio > 0.3) {
            // Show preview if URL is significant part of message
            this.showRichLinkPreviewForUrl(url);
          } else {
            this.hideRichLinkPreview();
          }
        } else {
          this.hideRichLinkPreview();
        }
      }, 500);
    },

    showRichLinkPreviewForUrl(url) {
      this.richLinkPreviewUrl = url;
      this.showRichLinkPreview = true;
    },

    hideRichLinkPreview() {
      this.showRichLinkPreview = false;
      this.richLinkPreviewUrl = '';
    },

    onRichLinkSendAsText(message) {
      // Send as regular text message
      this.message = message;
      this.onSendReply();
    },

    async onRichLinkSendAsRichLink(data) {
      try {
        // ✅ FIX: Process the message to split text and URLs properly
        const messageContent = data.originalMessage;
        const conversation = this.currentChat;

        // Use the processMessageForAppleMessages function to split the message
        const processedMessages = await processMessageForAppleMessages(
          messageContent,
          conversation
        );

        console.log('🔗 Processing message with URL:', messageContent);
        console.log('📝 Split into parts:', processedMessages.length);

        // ✅ CRITICAL FIX: Send messages sequentially with delay per Apple MSP docs
        console.log('📝 Processing', processedMessages.length, 'message(s)');

        if (processedMessages.length === 1) {
          // Single message (likely combined rich link) - send directly
          const messagePayload = {
            conversationId: this.currentChat.id,
            message: processedMessages[0].content,
            private: false,
            content_type: processedMessages[0].content_type,
            content_attributes: processedMessages[0].content_attributes || {},
          };

          console.log('📤 Sending single combined message:', messagePayload);

          await this.$store.dispatch(
            'createPendingMessageAndSend',
            messagePayload
          );
        } else {
          // Multiple messages - send sequentially with delays
          for (let i = 0; i < processedMessages.length; i++) {
            const messagePart = processedMessages[i];
            const messagePayload = {
              conversationId: this.currentChat.id,
              message: messagePart.content,
              private: false,
              content_type: messagePart.content_type,
              content_attributes: messagePart.content_attributes || {},
            };

            console.log(
              `📤 Sending message part ${i + 1}/${processedMessages.length}:`,
              messagePayload
            );

            await this.$store.dispatch(
              'createPendingMessageAndSend',
              messagePayload
            );

            if (i < processedMessages.length - 1) {
              console.log('⏳ Brief delay between messages...');
              await new Promise(resolve => setTimeout(resolve, 1500));
            }
          }
        }

        this.clearMessage();
        this.hideRichLinkPreview();
      } catch (error) {
        console.error('Rich Link send error:', error);
        const errorMessage =
          error?.message || this.$t('CONVERSATION.MESSAGE_ERROR');
        this.$store.dispatch('alerts/show', {
          message: errorMessage,
          type: 'error',
        });
      }
    },

    onRichLinkDismiss() {
      this.hideRichLinkPreview();
    },
  },
};
</script>

<template>
  <Banner
    v-if="showSelfAssignBanner"
    action-button-variant="ghost"
    color-scheme="secondary"
    class="mx-2 mb-2 rounded-lg banner--self-assign"
    :banner-message="$t('CONVERSATION.NOT_ASSIGNED_TO_YOU')"
    has-action-button
    :action-button-label="$t('CONVERSATION.ASSIGN_TO_ME')"
    @primary-action="onClickSelfAssign"
  />
  <div ref="replyEditor" class="reply-box" :class="replyBoxClass">
    <ReplyTopPanel
      :mode="replyType"
      :is-message-length-reaching-threshold="isMessageLengthReachingThreshold"
      :characters-remaining="charactersRemaining"
      :popout-reply-box="popOutReplyBox"
      @set-reply-mode="setReplyMode"
      @toggle-popout="togglePopout"
    />
    <ArticleSearchPopover
      v-if="showArticleSearchPopover && connectedPortalSlug"
      :selected-portal-slug="connectedPortalSlug"
      @insert="handleInsert"
      @close="onSearchPopoverClose"
    />
    <div class="reply-box__top">
      <ReplyToMessage
        v-if="shouldShowReplyToMessage"
        :message="inReplyTo"
        @dismiss="resetReplyToMessage"
      />
      <AppleRichLinkPreview
        v-if="showRichLinkPreview"
        :url="richLinkPreviewUrl"
        :conversation="currentChat"
        :original-message="message"
        @send-as-text="onRichLinkSendAsText"
        @send-as-rich-link="onRichLinkSendAsRichLink"
        @dismiss="onRichLinkDismiss"
      />
      <CannedResponse
        v-if="showMentions && hasSlashCommand"
        v-on-clickaway="hideMentions"
        class="normal-editor__canned-box"
        :search-key="mentionSearchKey"
        @replace="replaceText"
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
        v-if="showReplyHead"
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
      <ResizableTextArea
        v-else-if="!showRichContentEditor"
        ref="messageInput"
        v-model="message"
        class="rounded-none input"
        :placeholder="messagePlaceHolder"
        :min-height="4"
        :signature="signatureToApply"
        allow-signature
        :send-with-signature="sendWithSignature"
        @typing-off="onTypingOff"
        @typing-on="onTypingOn"
        @focus="onFocus"
        @blur="onBlur"
      />
      <WootMessageEditor
        v-else
        v-model="message"
        :editor-id="editorStateId"
        class="input"
        :is-private="isOnPrivateNote"
        :placeholder="messagePlaceHolder"
        :update-selection-with="updateEditorSelectionWith"
        :min-height="4"
        enable-variables
        :variables="messageVariables"
        :signature="signatureToApply"
        allow-signature
        :channel-type="channelType"
        @typing-off="onTypingOff"
        @typing-on="onTypingOn"
        @focus="onFocus"
        @blur="onBlur"
        @toggle-user-mention="toggleUserMention"
        @toggle-canned-menu="toggleCannedMenu"
        @toggle-variables-menu="toggleVariablesMenu"
        @clear-selection="clearEditorSelection"
      />
    </div>
    <div
      v-if="hasAttachments && !showAudioRecorderEditor"
      class="attachment-preview-box"
      @paste="onPaste"
    >
      <AttachmentPreview
        class="flex-col mt-4"
        :attachments="attachedFiles"
        @remove-attachment="removeAttachment"
      />
    </div>
    <MessageSignatureMissingAlert
      v-if="isSignatureEnabledForInbox && !isSignatureAvailable"
    />
    <ReplyBottomPanel
      :conversation-id="conversationId"
      :enable-multiple-file-upload="enableMultipleFileUpload"
      :enable-whats-app-templates="showWhatsappTemplates"
      :inbox="inbox"
      :is-on-private-note="isOnPrivateNote"
      :is-recording-audio="isRecordingAudio"
      :is-send-disabled="isReplyButtonDisabled"
      :mode="replyType"
      :on-file-upload="onFileUpload"
      :on-send="onSendReply"
      :conversation-type="conversationType"
      :recording-audio-duration-text="recordingAudioDurationText"
      :recording-audio-state="recordingAudioState"
      :send-button-text="replyButtonLabel"
      :show-audio-recorder="showAudioRecorder"
      :show-editor-toggle="isAPIInbox && !isOnPrivateNote"
      :show-emoji-picker="showEmojiPicker"
      :show-file-upload="showFileUpload"
      :toggle-audio-recorder-play-pause="toggleAudioRecorderPlayPause"
      :toggle-audio-recorder="toggleAudioRecorder"
      :toggle-emoji-picker="toggleEmojiPicker"
      :message="message"
      :portal-slug="connectedPortalSlug"
      :new-conversation-modal-active="newConversationModalActive"
      @select-whatsapp-template="openWhatsappTemplateModal"
      @toggle-editor="toggleRichContentEditor"
      @replace-text="replaceText"
      @toggle-insert-article="toggleInsertArticle"
      @send-apple-message="
        data => {
          console.log(
            '🔥 ReplyBox: received send-apple-message from ReplyBottomPanel:',
            data
          );
          sendAppleMessage(data);
        }
      "
    />
    <WhatsappTemplates
      :inbox-id="inbox.id"
      :show="showWhatsAppTemplatesModal"
      @close="hideWhatsappTemplatesModal"
      @on-send="onSendWhatsAppReply"
      @cancel="hideWhatsappTemplatesModal"
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

.banner--self-assign {
  @apply py-2;
}

.attachment-preview-box {
  @apply bg-transparent py-0 px-4;
}

.reply-box {
  transition: height 2s cubic-bezier(0.37, 0, 0.63, 1);

  @apply relative mb-2 mx-2 border border-n-weak rounded-xl bg-n-solid-1;

  &.is-private {
    @apply bg-n-solid-amber dark:border-n-amber-3/10 border-n-amber-12/5;
  }
}

.send-button {
  @apply mb-0;
}

.reply-box__top {
  @apply relative py-0 px-4 -mt-px;

  textarea {
    @apply shadow-none outline-none border-transparent bg-transparent m-0 max-h-60 min-h-[3rem] pt-4 pb-0 px-0 resize-none;
  }
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

.normal-editor__canned-box {
  width: calc(100% - 2 * 1rem);
  left: 1rem;
}
</style>
