<template>
  <div>
    <div v-if="hasAttachments" class="attachment-preview-box">
      <attachment-preview
        :attachments="attachedFiles"
        :remove-attachment="removeAttachment"
      />
    </div>
    <div class="reply-box" :class="replyBoxClass">
      <div class="reply-box__top" :class="{ 'is-private': isPrivate }">
        <canned-response
          v-if="showCannedResponsesList"
          v-on-clickaway="hideCannedResponse"
          data-dropdown-menu
          :on-keyenter="replaceText"
          :on-click="replaceText"
        />
        <emoji-input
          v-if="showEmojiPicker"
          v-on-clickaway="hideEmojiPicker"
          :on-click="emojiOnClick"
        />
        <resizable-text-area
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
        <file-upload
          v-if="showFileUpload"
          :size="4096 * 4096"
          accept="image/*, application/pdf, audio/mpeg, video/mp4, audio/ogg, text/csv"
          @input-file="onFileUpload"
        >
          <i class="icon ion-android-attach attachment" />
        </file-upload>
        <i
          class="icon ion-happy-outline"
          :class="{ active: showEmojiPicker }"
          @click="toggleEmojiPicker"
        />
      </div>

      <div class="reply-box__bottom">
        <ul class="tabs">
          <li class="tabs-title" :class="{ 'is-active': !isPrivate }">
            <a href="#" @click="setReplyMode">{{
              $t('CONVERSATION.REPLYBOX.REPLY')
            }}</a>
          </li>
          <li class="tabs-title is-private" :class="{ 'is-active': isPrivate }">
            <a href="#" @click="setPrivateReplyMode">
              {{ $t('CONVERSATION.REPLYBOX.PRIVATE_NOTE') }}
            </a>
          </li>
          <li v-if="message.length" class="tabs-title message-length">
            <a :class="{ 'message-error': isMessageLengthReachingThreshold }">
              {{ characterCountIndicator }}
            </a>
          </li>
        </ul>
        <button
          type="button"
          class="button send-button"
          :disabled="isReplyButtonDisabled"
          :class="{
            disabled: isReplyButtonDisabled,
            warning: isPrivate,
          }"
          @click="sendMessage"
        >
          {{ replyButtonLabel }}
          <i
            class="icon"
            :class="{
              'ion-android-send': !isPrivate,
              'ion-android-lock': isPrivate,
            }"
          />
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import FileUpload from 'vue-upload-component';

import EmojiInput from 'shared/components/emoji/EmojiInput';
import CannedResponse from './CannedResponse';
import ResizableTextArea from 'shared/components/ResizableTextArea';
import AttachmentPreview from 'dashboard/components/widgets/AttachmentsPreview';
import {
  isEscape,
  isEnter,
  hasPressedShift,
} from 'shared/helpers/KeyboardHelpers';
import { MESSAGE_MAX_LENGTH } from 'shared/helpers/MessageTypeHelper';
import inboxMixin from 'shared/mixins/inboxMixin';

export default {
  components: {
    EmojiInput,
    CannedResponse,
    FileUpload,
    ResizableTextArea,
    AttachmentPreview,
  },
  mixins: [clickaway, inboxMixin],
  props: {
    inReplyTo: {
      type: [String, Number],
      default: '',
    },
  },
  data() {
    return {
      message: '',
      isPrivateTabActive: false,
      isFocused: false,
      showEmojiPicker: false,
      showCannedResponsesList: false,
      attachedFiles: [],
    };
  },
  computed: {
    ...mapGetters({ currentChat: 'getSelectedChat' }),
    isPrivate() {
      if (this.currentChat.can_reply) {
        return this.isPrivateTabActive;
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
      return this.message.length > this.maxLength - 40;
    },
    characterCountIndicator() {
      return `${this.message.length} / ${this.maxLength}`;
    },
    isReplyButtonDisabled() {
      const isMessageEmpty = !this.message.trim().replace(/\n/g, '').length;

      if (this.hasAttachments) return false;
      return (
        isMessageEmpty ||
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
      if (this.isATwilioSMSChannel) {
        return MESSAGE_MAX_LENGTH.TWILIO_SMS;
      }
      if (this.isATwitterInbox) {
        if (this.conversationType === 'tweet') {
          return MESSAGE_MAX_LENGTH.TWEET;
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
        'is-focused': this.isFocused || this.hasAttachments,
      };
    },
    hasAttachments() {
      return this.attachedFiles.length;
    },
  },
  watch: {
    currentChat(conversation) {
      if (conversation.can_reply) {
        this.isPrivateTabActive = false;
      } else {
        this.isPrivateTabActive = true;
      }
    },
    message(updatedMessage) {
      if (this.isPrivate) {
        return;
      }
      const isSlashCommand = updatedMessage[0] === '/';
      const hasNextWord = updatedMessage.includes(' ');
      const isShortCodeActive = isSlashCommand && !hasNextWord;
      if (isShortCodeActive) {
        this.showCannedResponsesList = true;
        if (updatedMessage.length > 1) {
          const searchKey = updatedMessage.substr(1, updatedMessage.length);
          this.$store.dispatch('getCannedResponse', { searchKey });
        } else {
          this.$store.dispatch('getCannedResponse');
        }
      } else {
        this.showCannedResponsesList = false;
      }
    },
  },
  mounted() {
    document.addEventListener('keydown', this.handleKeyEvents);
  },
  destroyed() {
    document.removeEventListener('keydown', this.handleKeyEvents);
  },
  methods: {
    handleKeyEvents(e) {
      if (isEscape(e)) {
        this.hideEmojiPicker();
        this.hideCannedResponse();
      } else if (isEnter(e)) {
        if (!hasPressedShift(e)) {
          e.preventDefault();
          this.sendMessage();
        }
      }
    },
    async sendMessage() {
      if (this.isReplyButtonDisabled) {
        return;
      }
      if (!this.showCannedResponsesList) {
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
    setPrivateReplyMode() {
      this.isPrivateTabActive = true;
      this.$refs.messageInput.focus();
    },
    setReplyMode() {
      this.isPrivateTabActive = false;
      this.$refs.messageInput.focus();
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
    hideCannedResponse() {
      this.showCannedResponsesList = false;
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
      this.attachedFiles = [];
      if (!file) {
        return;
      }
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
  },
};
</script>

<style lang="scss">
@import '~widget/assets/scss/mixins';

.send-button {
  margin-bottom: 0;
}
.attachment-preview-box {
  margin: 0 var(--space-normal);
  background: var(--white);
  margin-bottom: var(--space-minus-slab);
  padding-top: var(--space-small);
  padding-bottom: var(--space-normal);
  border-top-left-radius: var(--border-radius-medium);
  border-top-right-radius: var(--border-radius-medium);
  @include shadow;
}
</style>
