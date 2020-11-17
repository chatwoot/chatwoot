<template>
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
        @focus="onFocus"
        @blur="onBlur"
      />
      <file-upload
        v-if="showFileUpload"
        :size="4096 * 4096"
        accept="image/*, application/pdf, audio/mpeg, video/mp4, audio/ogg"
        @input-file="onFileUpload"
      >
        <i v-if="!isUploading" class="icon ion-android-attach attachment" />
        <woot-spinner v-if="isUploading" />
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
</template>

<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';
import FileUpload from 'vue-upload-component';

import EmojiInput from 'shared/components/emoji/EmojiInput';
import CannedResponse from './CannedResponse';
import ResizableTextArea from 'shared/components/ResizableTextArea';
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
      isUploading: false,
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
        'is-focused': this.isFocused,
      };
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
      const newMessage = this.message;
      if (!this.showCannedResponsesList) {
        this.clearMessage();
        try {
          const messagePayload = {
            conversationId: this.currentChat.id,
            message: newMessage,
            private: this.isPrivate,
          };
          if (this.inReplyTo) {
            messagePayload.contentAttributes = { in_reply_to: this.inReplyTo };
          }
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
    onBlur() {
      this.isFocused = false;
      this.toggleTyping('off');
    },
    onFocus() {
      this.isFocused = true;
      this.toggleTyping('on');
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
      this.isUploading = true;
      this.$store
        .dispatch('sendAttachment', [
          this.currentChat.id,
          { file: file.file, isPrivate: this.isPrivate },
        ])
        .then(() => {
          this.isUploading = false;
          this.$emit('scrollToMessage');
        })
        .catch(() => {
          this.isUploading = false;
          this.$emit('scrollToMessage');
        });
    },
  },
};
</script>

<style lang="scss">
.send-button {
  margin-bottom: 0;
}
</style>
