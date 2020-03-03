<template>
  <div class="reply-box">
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
      <textarea
        ref="messageInput"
        v-model="message"
        rows="1"
        class="input"
        type="text"
        :placeholder="$t(messagePlaceHolder())"
        @click="onClick()"
        @blur="onBlur()"
      />
      <file-upload
        v-if="!showFileUpload"
        @input-file="onImage"
        accept="image/*"
      >
        <i class="icon ion-image attachment" v-if="!isUploading.image" />
        <woot-spinner v-if="isUploading.image" />
      </file-upload>
      <file-upload
        v-if="!showFileUpload"
        @input-file="onVideo"
        accept="video/*"
      >
        <i class="icon ion-videocamera attachment" v-if="!isUploading.video" />
        <woot-spinner v-if="isUploading.video" />
      </file-upload>
      <file-upload
        v-if="!showFileUpload"
        @input-file="onAudio"
        accept="audio/*"
      >
        <i class="icon ion-mic-a attachment" v-if="!isUploading.audio" />
        <woot-spinner v-if="isUploading.audio" />
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

export default {
  components: {
    EmojiInput,
    CannedResponse,
  },
  mixins: [clickaway],
  data() {
    return {
      message: '',
      isPrivate: false,
      showEmojiPicker: false,
      showFileUpload: false,
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
    replyButtonLabel() {
      if (this.isPrivate) {
        return this.$t('CONVERSATION.REPLYBOX.CREATE');
      }
      if (this.conversationType === 'tweet') {
        return this.$t('CONVERSATION.REPLYBOX.TWEET');
      }
      return this.$t('CONVERSATION.REPLYBOX.SEND');
    },
  },
  components: {
    EmojiInput,
    CannedResponse,
    FileUpload,
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
    sendMessage() {
      const isMessageEmpty = !this.message.replace(/\n/g, '').length;
      if (isMessageEmpty) {
        return;
      }
      if (!this.showCannedResponsesList) {
        this.$store
          .dispatch('sendMessage', {
            conversationId: this.currentChat.id,
            message: this.message,
            private: this.isPrivate,
          })
          .then(() => {
            this.$emit('scrollToMessage');
          });
        this.clearMessage();
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
      this.toggleTyping('off');
    },
    onClick() {
      this.markSeen();
      this.toggleTyping('on');
    },
    markSeen() {
      if (this.channelType === 'Channel::FacebookPage') {
        this.$store.dispatch('markSeen', {
          inboxId: this.currentChat.inbox_id,
          contactId: this.currentChat.meta.sender.id,
        });
      }
    },

    toggleTyping(status) {
      if (this.channelType === 'Channel::FacebookPage') {
        this.$store.dispatch('toggleTyping', {
          status,
          inboxId: this.currentChat.inbox_id,
          contactId: this.currentChat.meta.sender.id,
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

    onImage(file) {
      this.isUploading.image = true;
      this.$store
        .dispatch('sendAttachment', [
          this.currentChat.id,
          {
            file_type: 'image',
            file: file.file,
          },
        ])
        .then(() => {
          this.isUploading.image = false;
          this.$emit('scrollToMessage');
        });
    },
    onVideo({ file }) {
      this.isUploading.video = true;
      this.$store
        .dispatch('sendAttachment', [
          this.currentChat.id,
          {
            file_type: 'video',
            file,
          },
        ])
        .then(() => {
          this.isUploading.video = false;
          this.$emit('scrollToMessage');
        });
    },
    onAudio({ file }) {
      this.isUploading.audio = true;
      this.$store
        .dispatch('sendAttachment', [
          this.currentChat.id,
          {
            file_type: 'audio',
            file,
          },
        ])
        .then(() => {
          this.isUploading.audio = false;
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
