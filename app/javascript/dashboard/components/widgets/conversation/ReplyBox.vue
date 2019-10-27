<template>
  <div class="reply-box">
    <div class="reply-box__top" :class="{ 'is-private': isPrivate }">
      <canned-response
        v-if="showCannedModal"
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
      <i
        class="icon ion-happy-outline"
        :class="{ active: showEmojiPicker }"
        @click="toggleEmojiPicker()"
      ></i>
    </div>

    <div class="reply-box__bottom">
      <ul class="tabs">
        <li class="tabs-title" :class="{ 'is-active': !isPrivate }">
          <a href="#" @click="makeReply">Reply</a>
        </li>
        <li class="tabs-title is-private" :class="{ 'is-active': isPrivate }">
          <a href="#" @click="makePrivate">Private Note</a>
        </li>
        <li v-if="message.length" class="tabs-title message-length">
          <a :class="{ 'message-error': message.length > 620 }">
            {{ message.length }} / 640
          </a>
        </li>
      </ul>
      <button
        type="button"
        class="button send-button"
        :disabled="disableButton()"
        :class="{
          disabled: message.length === 0 || message.length > 640,
          warning: isPrivate,
        }"
        @click="sendMessage"
      >
        {{
          isPrivate
            ? $t('CONVERSATION.REPLYBOX.CREATE')
            : $t('CONVERSATION.REPLYBOX.SEND')
        }}
        <i
          class="icon"
          :class="{
            'ion-android-send': !isPrivate,
            'ion-android-lock': isPrivate,
          }"
        ></i>
      </button>
    </div>
  </div>
</template>

<script>
/* eslint no-console: 0 */

import { mapGetters } from 'vuex';
import emojione from 'emojione';
import { mixin as clickaway } from 'vue-clickaway';

import EmojiInput from '../emoji/EmojiInput';
import CannedResponse from './CannedResponse';

export default {
  mixins: [clickaway],
  data() {
    return {
      message: '',
      isPrivate: false,
      showEmojiPicker: false,
      showCannedModal: false,
    };
  },
  computed: mapGetters({
    currentChat: 'getSelectedChat',
  }),
  components: {
    EmojiInput,
    CannedResponse,
  },
  watch: {
    message(val) {
      if (this.isPrivate) {
        return;
      }
      const isSlashCommand = val[0] === '/';
      const hasNextWord = val.indexOf(' ') > -1;
      const isShortCodeActive = isSlashCommand && !hasNextWord;
      if (isShortCodeActive) {
        this.showCannedModal = true;
        if (val.length > 1) {
          const searchKey = val.substr(1, val.length);
          this.$store.dispatch('getCannedResponse', {
            searchKey,
          });
        } else {
          this.$store.dispatch('getCannedResponse');
        }
      } else {
        this.showCannedModal = false;
      }
    },
  },
  mounted() {
    /* eslint-disable no-confusing-arrow */
    document.addEventListener('keydown', e => {
      if (this.isEscape(e)) {
        this.hideEmojiPicker();
        this.hideCannedResponse();
      }
      if (this.isEnter(e)) {
        if (!e.shiftKey) {
          e.preventDefault();
          this.sendMessage();
        }
      }
    });
  },
  methods: {
    isEnter(e) {
      return e.keyCode === 13;
    },
    isEscape(e) {
      return e.keyCode === 27; // ESCAPE
    },
    sendMessage() {
      const messageHasOnlyNewLines = !this.message.replace(/\n/g, '').length;
      if (messageHasOnlyNewLines) {
        return;
      }
      if (this.message.length !== 0 && !this.showCannedModal) {
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
      }, 200);
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
      this.showCannedModal = false;
    },

    onBlur() {
      this.toggleTyping('off');
    },
    onClick() {
      this.markSeen();
      this.toggleTyping('on');
    },
    markSeen() {
      this.$store.dispatch('markSeen', {
        inboxId: this.currentChat.inbox_id,
        contactId: this.currentChat.meta.sender.id,
      });
    },

    toggleTyping(status) {
      this.$store.dispatch('toggleTyping', {
        status,
        inboxId: this.currentChat.inbox_id,
        contactId: this.currentChat.meta.sender.id,
      });
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
  },
};
</script>

<style lang="scss">
.send-button {
  margin-bottom: 0;
}
</style>
