<template>
  <div class="reply-box" :class="replyBoxClass">
    <reply-top-panel
      :mode="replyType"
      :set-reply-mode="setReplyMode"
      :is-message-length-reaching-threshold="isMessageLengthReachingThreshold"
      :characters-remaining="charactersRemaining"
    />
    <div class="reply-box__top">
      <canned-response
        v-if="showMentions && hasSlashCommand"
        v-on-clickaway="hideMentions"
        :search-key="mentionSearchKey"
        @click="replaceText"
      />
      <emoji-input
        v-if="showEmojiPicker"
        v-on-clickaway="hideEmojiPicker"
        :on-click="emojiOnClick"
      />
      <resizable-text-area
        v-if="!showRichContentEditor"
        ref="messageInput"
        v-model="message"
        class="input"
        :placeholder="messagePlaceHolder"
        :min-height="4"
        @typing-off="onTypingOff"
        @typing-on="onTypingOn"
        @focus="onFocus"
        @blur="onBlur"
      />
      <woot-message-editor
        v-else
        v-model="message"
        class="input"
        :is-private="isOnPrivateNote"
        :placeholder="messagePlaceHolder"
        :min-height="4"
        @typing-off="onTypingOff"
        @typing-on="onTypingOn"
        @focus="onFocus"
        @blur="onBlur"
        @toggle-user-mention="toggleUserMention"
        @toggle-canned-menu="toggleCannedMenu"
      />
    </div>
    <div v-if="hasAttachments" class="attachment-preview-box">
      <attachment-preview
        :attachments="attachedFiles"
        :remove-attachment="removeAttachment"
      />
    </div>
    <reply-bottom-panel
      :mode="replyType"
      :send-button-text="replyButtonLabel"
      :on-file-upload="onFileUpload"
      :show-file-upload="showFileUpload"
      :toggle-emoji-picker="toggleEmojiPicker"
      :show-emoji-picker="showEmojiPicker"
      :on-send="sendMessage"
      :is-send-disabled="isReplyButtonDisabled"
      :set-format-mode="setFormatMode"
      :is-on-private-note="isOnPrivateNote"
      :is-format-mode="showRichContentEditor"
      :enable-rich-editor="isRichEditorEnabled"
      :enter-to-send-enabled="enterToSendEnabled"
      @toggleEnterToSend="toggleEnterToSend"
    />
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import alertMixin from 'shared/mixins/alertMixin';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';

import EmojiInput from 'shared/components/emoji/EmojiInput';
import CannedResponse from './CannedResponse';
import ResizableTextArea from 'shared/components/ResizableTextArea';
import AttachmentPreview from 'dashboard/components/widgets/AttachmentsPreview';
import ReplyTopPanel from 'dashboard/components/widgets/WootWriter/ReplyTopPanel';
import ReplyBottomPanel from 'dashboard/components/widgets/WootWriter/ReplyBottomPanel';
import { REPLY_EDITOR_MODES } from 'dashboard/components/widgets/WootWriter/constants';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor';
import { checkFileSizeLimit } from 'shared/helpers/FileHelper';
import { MAXIMUM_FILE_UPLOAD_SIZE } from 'shared/constants/messages';

import {
  isEscape,
  isEnter,
  hasPressedShift,
} from 'shared/helpers/KeyboardHelpers';
import { MESSAGE_MAX_LENGTH } from 'shared/helpers/MessageTypeHelper';
import inboxMixin from 'shared/mixins/inboxMixin';
import uiSettingsMixin from 'dashboard/mixins/uiSettings';

export default {
  components: {
    EmojiInput,
    CannedResponse,
    ResizableTextArea,
    AttachmentPreview,
    ReplyTopPanel,
    ReplyBottomPanel,
    WootMessageEditor,
  },
  mixins: [
    clickaway,
    inboxMixin,
    uiSettingsMixin,
    alertMixin,
    eventListenerMixins,
  ],
  props: {
    selectedTweet: {
      type: [Object, String],
      default: () => ({}),
    },
    isATweet: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      message: '',
      isFocused: false,
      showEmojiPicker: false,
      showMentions: false,
      attachedFiles: [],
      isUploading: false,
      replyType: REPLY_EDITOR_MODES.REPLY,
      mentionSearchKey: '',
      hasUserMention: false,
      hasSlashCommand: false,
    };
  },
  computed: {
    showRichContentEditor() {
      if (this.isOnPrivateNote) {
        return true;
      }

      if (this.isRichEditorEnabled) {
        const {
          display_rich_content_editor: displayRichContentEditor,
        } = this.uiSettings;

        return displayRichContentEditor;
      }
      return false;
    },
    ...mapGetters({ currentChat: 'getSelectedChat' }),
    enterToSendEnabled() {
      return !!this.uiSettings.enter_to_send_enabled;
    },
    isPrivate() {
      if (this.currentChat.can_reply || this.isATwilioWhatsappChannel) {
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
      if (this.isATweet && !this.inReplyTo) {
        return true;
      }

      if (this.hasAttachments) return false;

      return (
        this.isMessageEmpty ||
        this.message.length === 0 ||
        this.message.length > this.maxLength
      );
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
      if (this.isATwilioWhatsappChannel) {
        return MESSAGE_MAX_LENGTH.TWILIO_WHATSAPP;
      }
      if (this.isATwilioSMSChannel) {
        return MESSAGE_MAX_LENGTH.TWILIO_SMS;
      }
      if (this.isATwitterInbox) {
        if (this.conversationType === 'tweet') {
          return MESSAGE_MAX_LENGTH.TWEET - this.replyToUserLength - 2;
        }
      }
      return MESSAGE_MAX_LENGTH.GENERAL;
    },
    showFileUpload() {
      return (
        this.isAWebWidgetInbox ||
        this.isAFacebookInbox ||
        this.isATwilioWhatsappChannel ||
        this.isAPIInbox
      );
    },
    replyButtonLabel() {
      if (this.isPrivate) {
        return this.$t('CONVERSATION.REPLYBOX.CREATE');
      }
      if (this.conversationType === 'tweet') {
        return this.$t('CONVERSATION.REPLYBOX.TWEET');
      }
      return this.$t('CONVERSATION.REPLYBOX.SEND');
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
    isOnPrivateNote() {
      return this.replyType === REPLY_EDITOR_MODES.NOTE;
    },
    inReplyTo() {
      const selectedTweet = this.selectedTweet || {};
      return selectedTweet.id;
    },
    replyToUserLength() {
      const selectedTweet = this.selectedTweet || {};
      const {
        sender: {
          additional_attributes: { screen_name: screenName = '' } = {},
        } = {},
      } = selectedTweet;
      return screenName ? screenName.length : 0;
    },
    isMessageEmpty() {
      if (!this.message) {
        return true;
      }
      return !this.message.trim().replace(/\n/g, '').length;
    },
  },
  watch: {
    currentChat(conversation) {
      const { can_reply: canReply } = conversation;
      if (this.isOnPrivateNote) {
        return;
      }

      if (canReply || this.isATwilioWhatsappChannel) {
        this.replyType = REPLY_EDITOR_MODES.REPLY;
      } else {
        this.replyType = REPLY_EDITOR_MODES.NOTE;
      }
    },
    message(updatedMessage) {
      this.hasSlashCommand =
        updatedMessage[0] === '/' && !this.showRichContentEditor;
      const hasNextWord = updatedMessage.includes(' ');
      const isShortCodeActive = this.hasSlashCommand && !hasNextWord;
      if (isShortCodeActive) {
        this.mentionSearchKey = updatedMessage.substr(1, updatedMessage.length);
        this.showMentions = true;
      } else {
        this.mentionSearchKey = '';
        this.showMentions = false;
      }
    },
  },
  methods: {
    toggleUserMention(currentMentionState) {
      this.hasUserMention = currentMentionState;
    },
    toggleCannedMenu(value) {
      this.showCannedMenu = value;
    },
    handleKeyEvents(e) {
      if (isEscape(e)) {
        this.hideEmojiPicker();
        this.hideMentions();
      } else if (isEnter(e)) {
        const hasSendOnEnterEnabled =
          (this.showRichContentEditor &&
            this.enterToSendEnabled &&
            !this.hasUserMention &&
            !this.showCannedMenu) ||
          !this.showRichContentEditor;
        const shouldSendMessage =
          hasSendOnEnterEnabled && !hasPressedShift(e) && this.isFocused;
        if (shouldSendMessage) {
          e.preventDefault();
          this.sendMessage();
        }
      }
    },
    toggleEnterToSend(enterToSendEnabled) {
      this.updateUISettings({ enter_to_send_enabled: enterToSendEnabled });
    },
    async sendMessage() {
      if (this.isReplyButtonDisabled) {
        return;
      }
      if (!this.showMentions) {
        const newMessage = this.message;
        const messagePayload = this.getMessagePayload(newMessage);
        this.clearMessage();
        try {
          await this.$store.dispatch('sendMessage', messagePayload);
          this.$emit('scrollToMessage');
        } catch (error) {
          // Error
        }
        this.hideEmojiPicker();
      }
    },
    replaceText(message) {
      setTimeout(() => {
        this.message = message;
      }, 100);
    },
    setReplyMode(mode = REPLY_EDITOR_MODES.REPLY) {
      const { can_reply: canReply } = this.currentChat;

      if (canReply || this.isATwilioWhatsappChannel) this.replyType = mode;
      if (this.showRichContentEditor) {
        return;
      }
      if (this.$refs.messageInput === undefined) {
        return;
      }
      this.$nextTick(() => this.$refs.messageInput.focus());
    },
    emojiOnClick(emoji) {
      this.message = `${this.message}${emoji} `;
    },
    clearMessage() {
      this.message = '';
      this.attachedFiles = [];
    },
    toggleEmojiPicker() {
      this.showEmojiPicker = !this.showEmojiPicker;
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
    },
    onFocus() {
      this.isFocused = true;
    },
    toggleTyping(status) {
      if (this.isAWebWidgetInbox && !this.isPrivate) {
        const conversationId = this.currentChat.id;
        this.$store.dispatch('conversationTypingStatus/toggleTyping', {
          status,
          conversationId,
        });
      }
    },
    onFileUpload(file) {
      if (!file) {
        return;
      }
      if (checkFileSizeLimit(file, MAXIMUM_FILE_UPLOAD_SIZE)) {
        this.attachedFiles = [];
        const reader = new FileReader();
        reader.readAsDataURL(file.file);
        reader.onloadend = () => {
          this.attachedFiles.push({
            currentChatId: this.currentChat.id,
            resource: file,
            isPrivate: this.isPrivate,
            thumb: reader.result,
          });
        };
      } else {
        this.showAlert(
          this.$t('CONVERSATION.FILE_SIZE_LIMIT', {
            MAXIMUM_FILE_UPLOAD_SIZE,
          })
        );
      }
    },
    removeAttachment(itemIndex) {
      this.attachedFiles = this.attachedFiles.filter(
        (item, index) => itemIndex !== index
      );
    },
    getMessagePayload(message) {
      const [attachment] = this.attachedFiles;
      const messagePayload = {
        conversationId: this.currentChat.id,
        message,
        private: this.isPrivate,
      };

      if (this.inReplyTo) {
        messagePayload.contentAttributes = { in_reply_to: this.inReplyTo };
      }

      if (attachment) {
        messagePayload.file = attachment.resource.file;
      }

      return messagePayload;
    },
    setFormatMode(value) {
      this.updateUISettings({ display_rich_content_editor: value });
    },
  },
};
</script>

<style lang="scss" scoped>
.send-button {
  margin-bottom: 0;
}

.attachment-preview-box {
  padding: 0 var(--space-normal);
  background: transparent;
}

.reply-box {
  border-top: 1px solid var(--color-border);
  background: white;

  &.is-private {
    background: var(--y-50);
  }
}
.send-button {
  margin-bottom: 0;
}

.reply-box__top {
  padding: 0 var(--space-normal);
  border-top: 1px solid var(--color-border);
  margin-top: -1px;
}

.emoji-dialog {
  top: unset;
  bottom: 12px;
  left: -320px;
  right: unset;

  &::before {
    right: -16px;
    bottom: 10px;
    transform: rotate(270deg);
    filter: drop-shadow(0px 4px 4px rgba(0, 0, 0, 0.08));
  }
}
</style>
