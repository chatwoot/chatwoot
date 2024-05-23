<template>
  <div class="reply-box" :class="replyBoxClass">
    <banner
      v-if="showSelfAssignBanner"
      action-button-variant="clear"
      color-scheme="secondary"
      class="banner--self-assign"
      :banner-message="$t('CONVERSATION.NOT_ASSIGNED_TO_YOU')"
      :has-action-button="true"
      :action-button-label="$t('CONVERSATION.ASSIGN_TO_ME')"
      @click="onClickSelfAssign"
    />
    <reply-top-panel
      :mode="replyType"
      :set-reply-mode="setReplyMode"
      :is-message-length-reaching-threshold="isMessageLengthReachingThreshold"
      :characters-remaining="charactersRemaining"
      :popout-reply-box="popoutReplyBox"
      @click="$emit('click')"
    />
    <article-search-popover
      v-if="showArticleSearchPopover && connectedPortalSlug"
      :selected-portal-slug="connectedPortalSlug"
      @insert="handleInsert"
      @close="onSearchPopoverClose"
    />
    <div class="reply-box__top">
      <reply-to-message
        v-if="shouldShowReplyToMessage"
        :message="inReplyTo"
        @dismiss="resetReplyToMessage"
      />
      <canned-response
        v-if="showMentions && hasSlashCommand"
        v-on-clickaway="hideMentions"
        class="normal-editor__canned-box"
        :search-key="mentionSearchKey"
        @click="replaceText"
      />
      <emoji-input
        v-if="showEmojiPicker"
        v-on-clickaway="hideEmojiPicker"
        :class="emojiDialogClassOnExpandedLayoutAndRTLView"
        :on-click="addIntoEditor"
      />
      <reply-email-head
        v-if="showReplyHead"
        :cc-emails.sync="ccEmails"
        :bcc-emails.sync="bccEmails"
        :to-emails.sync="toEmails"
      />
      <woot-audio-recorder
        v-if="showAudioRecorderEditor"
        ref="audioRecorderInput"
        :audio-record-format="audioRecordFormat"
        @state-recorder-progress-changed="onStateProgressRecorderChanged"
        @state-recorder-changed="onStateRecorderChanged"
        @finish-record="onFinishRecorder"
      />
      <resizable-text-area
        v-else-if="!showRichContentEditor"
        ref="messageInput"
        v-model="message"
        class="input"
        :placeholder="messagePlaceHolder"
        :min-height="4"
        :signature="signatureToApply"
        :allow-signature="true"
        :send-with-signature="sendWithSignature"
        @typing-off="onTypingOff"
        @typing-on="onTypingOn"
        @focus="onFocus"
        @blur="onBlur"
      />
      <woot-message-editor
        v-else
        v-model="message"
        :editor-id="editorStateId"
        class="input"
        :is-private="isOnPrivateNote"
        :placeholder="messagePlaceHolder"
        :update-selection-with="updateEditorSelectionWith"
        :min-height="4"
        :enable-variables="true"
        :variables="messageVariables"
        :signature="signatureToApply"
        :allow-signature="true"
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
    <div v-if="hasAttachments" class="attachment-preview-box" @paste="onPaste">
      <attachment-preview
        class="flex-col mt-4"
        :attachments="attachedFiles"
        @remove-attachment="removeAttachment"
      />
    </div>
    <message-signature-missing-alert
      v-if="isSignatureEnabledForInbox && !isSignatureAvailable"
    />
    <reply-bottom-panel
      :conversation-id="conversationId"
      :enable-multiple-file-upload="enableMultipleFileUpload"
      :has-whatsapp-templates="hasWhatsappTemplates"
      :inbox="inbox"
      :is-on-private-note="isOnPrivateNote"
      :is-recording-audio="isRecordingAudio"
      :is-send-disabled="isReplyButtonDisabled"
      :mode="replyType"
      :on-file-upload="onFileUpload"
      :on-send="onSendReply"
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
      @selectWhatsappTemplate="openWhatsappTemplateModal"
      @toggle-editor="toggleRichContentEditor"
      @replace-text="replaceText"
      @toggle-insert-article="toggleInsertArticle"
    />
    <whatsapp-templates
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

<script>
import { mapGetters } from 'vuex';
import alertMixin from 'shared/mixins/alertMixin';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';

import CannedResponse from './CannedResponse.vue';
import ReplyToMessage from './ReplyToMessage.vue';
import ResizableTextArea from 'shared/components/ResizableTextArea.vue';
import AttachmentPreview from 'dashboard/components/widgets/AttachmentsPreview.vue';
import ReplyTopPanel from 'dashboard/components/widgets/WootWriter/ReplyTopPanel.vue';
import ReplyEmailHead from './ReplyEmailHead.vue';
import ReplyBottomPanel from 'dashboard/components/widgets/WootWriter/ReplyBottomPanel.vue';
import ArticleSearchPopover from 'dashboard/routes/dashboard/helpcenter/components/ArticleSearch/SearchPopover.vue';
import MessageSignatureMissingAlert from './MessageSignatureMissingAlert';
import Banner from 'dashboard/components/ui/Banner.vue';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';
import WootAudioRecorder from 'dashboard/components/widgets/WootWriter/AudioRecorder.vue';
import messageFormatterMixin from 'shared/mixins/messageFormatterMixin';
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
import uiSettingsMixin from 'dashboard/mixins/uiSettings';
import { trimContent, debounce } from '@chatwoot/utils';
import wootConstants from 'dashboard/constants/globals';
import { isEditorHotKeyEnabled } from 'dashboard/mixins/uiSettings';
import { CONVERSATION_EVENTS } from '../../../helper/AnalyticsHelper/events';
import rtlMixin from 'shared/mixins/rtlMixin';
import fileUploadMixin from 'dashboard/mixins/fileUploadMixin';
import {
  appendSignature,
  removeSignature,
  replaceSignature,
  extractTextFromMarkdown,
} from 'dashboard/helper/editorHelper';

import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';

const EmojiInput = () => import('shared/components/emoji/EmojiInput');

export default {
  components: {
    EmojiInput,
    CannedResponse,
    ReplyToMessage,
    ResizableTextArea,
    AttachmentPreview,
    ReplyTopPanel,
    ReplyEmailHead,
    ReplyBottomPanel,
    WootMessageEditor,
    WootAudioRecorder,
    Banner,
    WhatsappTemplates,
    MessageSignatureMissingAlert,
    ArticleSearchPopover,
  },
  mixins: [
    inboxMixin,
    uiSettingsMixin,
    alertMixin,
    messageFormatterMixin,
    rtlMixin,
    fileUploadMixin,
    keyboardEventListenerMixins,
  ],
  props: {
    popoutReplyBox: {
      type: Boolean,
      default: false,
    },
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
            this.showAlert(this.$t('CONVERSATION.CHANGE_AGENT'));
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
    hasWhatsappTemplates() {
      return !!this.$store.getters['inboxes/getWhatsAppTemplates'](this.inboxId)
        .length;
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
      if (this.isAWhatsAppChannel) {
        return MESSAGE_MAX_LENGTH.TWILIO_WHATSAPP;
      }
      if (this.isASmsInbox) {
        return MESSAGE_MAX_LENGTH.TWILIO_SMS;
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
        this.isALineChannel
      );
    },
    replyButtonLabel() {
      let sendMessageText = this.$t('CONVERSATION.REPLYBOX.SEND');
      if (this.isPrivate) {
        sendMessageText = this.$t('CONVERSATION.REPLYBOX.CREATE');
      }
      const keyLabel = isEditorHotKeyEnabled(this.uiSettings, 'cmd_enter')
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
    hasRecordedAudio() {
      return (
        this.$refs.audioRecorderInput &&
        this.$refs.audioRecorderInput.hasAudio()
      );
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
    emojiDialogClassOnExpandedLayoutAndRTLView() {
      if (this.isOnExpandedLayout || this.popoutReplyBox) {
        return 'emoji-dialog--expanded';
      }
      if (this.isRTLView) {
        return 'emoji-dialog--rtl';
      }
      return '';
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
        this.isAWhatsAppChannel
      );
    },
    isSignatureEnabledForInbox() {
      return !this.isPrivate && this.sendWithSignature;
    },
    isSignatureAvailable() {
      return !!this.signatureToApply;
    },
    sendWithSignature() {
      return this.fetchSignatureFlagFromUiSettings(this.channelType);
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
        return AUDIO_FORMATS.OGG;
      }
      return AUDIO_FORMATS.WAV;
    },
    messageVariables() {
      const variables = getMessageVariables({
        conversation: this.currentChat,
        contact: this.currentContact,
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
    currentChat(conversation) {
      const { can_reply: canReply } = conversation;

      this.setCCAndToEmailsFromLastChat();

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
    conversationIdByRoute(conversationId, oldConversationId) {
      if (conversationId !== oldConversationId) {
        this.setToDraft(oldConversationId, this.replyType);
        this.getFromDraft();
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
    bus.$on(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.fetchAndSetReplyTo);

    // A hacky fix to solve the drag and drop
    // Is showing on top of new conversation modal drag and drop
    // TODO need to find a better solution
    bus.$on(
      BUS_EVENTS.NEW_CONVERSATION_MODAL,
      this.onNewConversationModalActive
    );
  },
  destroyed() {
    document.removeEventListener('paste', this.onPaste);
    document.removeEventListener('keydown', this.handleKeyEvents);
    bus.$off(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE, this.fetchAndSetReplyTo);
  },
  beforeDestroy() {
    bus.$off(
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
        bus.$emit(
          BUS_EVENTS.INSERT_INTO_RICH_EDITOR,
          `[${filteredMarkdown}](${url})`
        );
      } else {
        this.addIntoEditor(
          `${this.$t('CONVERSATION.REPLYBOX.INSERT_READ_MORE')} ${url}`
        );
      }

      this.$track(CONVERSATION_EVENTS.INSERT_ARTICLE_LINK);
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
        isEditorHotKeyEnabled(this.uiSettings, selectedKey)
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
        if (isOnWhatsApp && !this.isPrivate) {
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
        this.$emit('update:popoutReplyBox', false);
      }
    },
    sendMessageAsMultipleMessages(message) {
      const messages = this.getMessagePayloadForWhatsapp(message);
      messages.forEach(messagePayload => {
        this.sendMessage(messagePayload);
      });
    },
    sendMessageAnalyticsData(isPrivate) {
      // Analytics data for message signature is enabled or not in channels
      return isPrivate
        ? this.$track(CONVERSATION_EVENTS.SENT_PRIVATE_NOTE)
        : this.$track(CONVERSATION_EVENTS.SENT_MESSAGE, {
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
        bus.$emit(BUS_EVENTS.SCROLL_TO_MESSAGE);
        bus.$emit(BUS_EVENTS.MESSAGE_SENT);
        this.removeFromDraft();
        this.sendMessageAnalyticsData(messagePayload.private);
      } catch (error) {
        const errorMessage =
          error?.response?.data?.error || this.$t('CONVERSATION.MESSAGE_ERROR');
        this.showAlert(errorMessage);
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
        this.$track(CONVERSATION_EVENTS.INSERTED_A_CANNED_RESPONSE);
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
    },
    clearEmailField() {
      this.ccEmails = '';
      this.bccEmails = '';
      this.toEmails = '';
    },
    clearRecorder() {
      this.isRecordingAudio = false;
      // Only clear the recorded audio when we click toggle button.
      this.attachedFiles = this.attachedFiles.filter(
        file => !file?.isRecordedAudio
      );
    },
    toggleEmojiPicker() {
      this.showEmojiPicker = !this.showEmojiPicker;
    },
    toggleAudioRecorder() {
      this.isRecordingAudio = !this.isRecordingAudio;
      this.isRecorderAudioStopped = !this.isRecordingAudio;
      if (!this.isRecordingAudio) {
        this.clearRecorder();
      }
    },
    toggleAudioRecorderPlayPause() {
      if (this.isRecordingAudio) {
        if (!this.isRecorderAudioStopped) {
          this.isRecorderAudioStopped = true;
          this.$refs.audioRecorderInput.stopAudioRecording();
        } else if (this.isRecorderAudioStopped) {
          this.$refs.audioRecorderInput.playPause();
        }
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
    onStateProgressRecorderChanged(duration) {
      this.recordingAudioDurationText = duration;
    },
    onStateRecorderChanged(state) {
      this.recordingAudioState = state;
      if (state && 'notallowederror'.includes(state)) {
        this.toggleAudioRecorder();
      }
    },
    onFinishRecorder(file) {
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
    getMessagePayloadForWhatsapp(message) {
      const multipleMessagePayload = [];

      if (this.attachedFiles && this.attachedFiles.length) {
        let caption = message;
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
          caption = '';
        });
      } else {
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
      let messagePayload = {
        conversationId: this.currentChat.id,
        message,
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
      if (!this.lastEmail) return;

      const {
        content_attributes: { email: emailAttributes = {} },
      } = this.lastEmail;

      // Retrieve the email of the current conversation's sender
      const conversationContact = this.currentChat?.meta?.sender?.email || '';
      let cc = emailAttributes.cc ? [...emailAttributes.cc] : [];
      let to = [];

      // there might be a situation where the current conversation will include a message from a third person,
      // and the current conversation contact is in CC.
      // This is an edge-case, reported here: CW-1511 [ONLY FOR INTERNAL REFERENCE]
      // So we remove the current conversation contact's email from the CC list if present
      if (cc.includes(conversationContact)) {
        cc = cc.filter(email => email !== conversationContact);
      }

      // If the last incoming message sender is different from the conversation contact, add them to the "to"
      // and add the conversation contact to the CC
      if (!emailAttributes.from.includes(conversationContact)) {
        to.push(...emailAttributes.from);
        cc.push(conversationContact);
      }

      // Remove the conversation contact's email from the BCC list if present
      let bcc = (emailAttributes.bcc || []).filter(
        email => email !== conversationContact
      );

      // Ensure only unique email addresses are in the CC list
      bcc = [...new Set(bcc)];
      cc = [...new Set(cc)];
      to = [...new Set(to)];

      this.ccEmails = cc.join(', ');
      this.bccEmails = bcc.join(', ');
      this.toEmails = to.join(', ');
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
      bus.$emit(BUS_EVENTS.TOGGLE_REPLY_TO_MESSAGE);
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
  },
};
</script>

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
  transition:
    box-shadow 0.35s cubic-bezier(0.37, 0, 0.63, 1),
    height 2s cubic-bezier(0.37, 0, 0.63, 1);

  @apply relative border-t border-slate-50 dark:border-slate-700 bg-white dark:bg-slate-900;

  &.is-focused {
    box-shadow:
      0 1px 3px 0 rgba(0, 0, 0, 0.1),
      0 1px 2px 0 rgba(0, 0, 0, 0.06);
  }

  &.is-private {
    @apply bg-yellow-100 dark:bg-yellow-800;

    .reply-box__top {
      @apply bg-yellow-100 dark:bg-yellow-800;

      > input {
        @apply bg-yellow-100 dark:bg-yellow-800;
      }
    }
  }
}

.send-button {
  @apply mb-0;
}

.reply-box__top {
  @apply relative py-0 px-4 -mt-px border-t border-solid border-slate-50 dark:border-slate-700;

  textarea {
    @apply shadow-none border-transparent bg-transparent m-0 max-h-60 min-h-[3rem] pt-4 pb-0 px-0 resize-none;
  }
}

.emoji-dialog {
  @apply top-[unset] -bottom-10 -left-80 right-[unset];

  &::before {
    transform: rotate(270deg);
    filter: drop-shadow(0px 4px 4px rgba(0, 0, 0, 0.08));
    @apply -right-4 bottom-2 rtl:right-0 rtl:-left-4;
  }
}

.emoji-dialog--rtl {
  @apply left-[unset] -right-80;

  &::before {
    transform: rotate(90deg);
    filter: drop-shadow(0px 4px 4px rgba(0, 0, 0, 0.08));
  }
}

.emoji-dialog--expanded {
  @apply left-[unset] bottom-0 absolute z-[100];

  &::before {
    transform: rotate(0deg);
    @apply left-1 -bottom-2;
  }
}

.normal-editor__canned-box {
  width: calc(100% - 2 * var(--space-normal));
  left: var(--space-normal);
}
</style>
