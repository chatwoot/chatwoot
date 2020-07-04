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
        :placeholder="$t(messagePlaceHolder())"
        :min-height="4"
        @focus="onFocus"
        @blur="onBlur"
      />
      <file-upload
        v-if="showFileUpload"
        :size="4096 * 4096"
        accept="jpg,jpeg,png,mp3,ogg,amr,pdf,mp4"
        @input-file="onFileUpload"
      >
        <i
          v-if="!isUploading.image"
          class="icon ion-android-attach attachment"
        />
        <woot-spinner v-if="isUploading.image" />
      </file-upload>
      <i
        class="icon ion-happy-outline"
        :class="{ active: showEmojiPicker }"
        @click="toggleEmojiPicker()"
      />
    </div>

    <div class="reply-box__bottom">
      <ul class="tabs">
        <li class="tabs-title" :class="{ 'is-active': !isPrivate }">
          <a href="#" @click="makeReply">{{
            $t('CONVERSATION.REPLYBOX.REPLY')
          }}</a>
        </li>
        <li class="tabs-title is-private" :class="{ 'is-active': isPrivate }">
          <a href="#" @click="makePrivate">{{
            $t('CONVERSATION.REPLYBOX.PRIVATE_NOTE')
          }}</a>
        </li>
        <li v-if="message.length" class="tabs-title message-length">
          <a :class="{ 'message-error': message.length > maxLength - 40 }">
            {{ message.length }} / {{ maxLength }}
          </a>
        </li>
      </ul>
      <button
        type="button"
        class="button send-button"
        :disabled="disableButton()"
        :class="{
          disabled: message.length === 0 || message.length > maxLength,
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
/* eslint no-console: 0 */

import { mapGetters } from 'vuex';
import emojione from 'emojione';
import { mixin as clickaway } from 'vue-clickaway';
import FileUpload from 'vue-upload-component';

import EmojiInput from '../emoji/EmojiInput';
import CannedResponse from './CannedResponse';
import ResizableTextArea from 'shared/components/ResizableTextArea';

export default {
  components: {
    EmojiInput,
    CannedResponse,
    FileUpload,
    ResizableTextArea,
  },
  mixins: [clickaway],
  data() {
    return {
      message: '',
      isPrivate: false,
      isFocused: false,
      showEmojiPicker: false,
      showCannedResponsesList: false,
      isUploading: {
        audio: false,
        video: false,
        image: false,
      },
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    channelType() {
      const {
        meta: {
          sender: { channel },
        },
      } = this.currentChat;
      return channel;
    },
    conversationType() {
      const { additional_attributes: additionalAttributes } = this.currentChat;
      const type = additionalAttributes ? additionalAttributes.type : '';
      return type || '';
    },
    maxLength() {
      if (this.channelType === 'Channel::FacebookPage') {
        return 640;
      }
      if (this.channelType === 'Channel::TwitterProfile') {
        if (this.conversationType === 'tweet') {
          return 280;
        }
      }
      return 10000;
    },
    showFileUpload() {
      return (
        this.channelType === 'Channel::WebWidget' ||
        this.channelType === 'Channel::TwilioSms'
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
    message(val) {
      if (this.isPrivate) {
        return;
      }
      const isSlashCommand = val[0] === '/';
      const hasNextWord = val.includes(' ');
      const isShortCodeActive = isSlashCommand && !hasNextWord;
      if (isShortCodeActive) {
        this.showCannedResponsesList = true;
        if (val.length > 1) {
          const searchKey = val.substr(1, val.length);
          this.$store.dispatch('getCannedResponse', {
            searchKey,
          });
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
      if (this.isEscape(e)) {
        this.hideEmojiPicker();
        this.hideCannedResponse();
      } else if (this.isEnter(e)) {
        if (!e.shiftKey) {
          e.preventDefault();
          this.sendMessage();
        }
      }
    },
    isEnter(e) {
      return e.keyCode === 13;
    },
    isEscape(e) {
      return e.keyCode === 27; // ESCAPE
    },
    async sendMessage() {
      const isMessageEmpty = !this.message.replace(/\n/g, '').length;
      if (isMessageEmpty) return;
      if (this.message.length > this.maxLength) {
        return;
      }
      const newMessage = this.message;
      if (!this.showCannedResponsesList) {
        this.clearMessage();
        try {
          await this.$store.dispatch('sendMessage', {
            conversationId: this.currentChat.id,
            message: newMessage,
            private: this.isPrivate,
          });
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
    makePrivate() {
      this.isPrivate = true;
      this.$refs.messageInput.focus();
    },
    makeReply() {
      this.isPrivate = false;
      this.$refs.messageInput.focus();
    },
    emojiOnClick(emoji) {
      this.message = emojione.shortnameToUnicode(
        `${this.message}${emoji.shortname} `
      );
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
      if (this.channelType === 'Channel::WebWidget' && !this.isPrivate) {
        const conversationId = this.currentChat.id;
        this.$store.dispatch('conversationTypingStatus/toggleTyping', {
          status,
          conversationId,
        });
      }
    },
    disableButton() {
      const messageHasOnlyNewLines = !this.message.replace(/\n/g, '').length;
      return (
        this.message.length === 0 ||
        this.message.length > 640 ||
        messageHasOnlyNewLines
      );
    },

    messagePlaceHolder() {
      const placeHolder = this.isPrivate
        ? 'CONVERSATION.FOOTER.PRIVATE_MSG_INPUT'
        : 'CONVERSATION.FOOTER.MSG_INPUT';
      return placeHolder;
    },

    onFileUpload(file) {
      if (!file) {
        return;
      }
      this.isUploading.image = true;
      this.$store
        .dispatch('sendAttachment', [this.currentChat.id, { file: file.file }])
        .then(() => {
          this.isUploading.image = false;
          this.$emit('scrollToMessage');
        })
        .catch(() => {
          this.isUploading.image = false;
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
