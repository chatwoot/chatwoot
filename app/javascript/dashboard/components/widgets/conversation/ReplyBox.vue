<template>
  <div class="reply-box">
    <div class="reply-box__top" :class="{ 'is-private': private }">
      <canned-response
        v-on-clickaway="hideCannedResponse"
        data-dropdown-menu
        :on-keyenter="replaceText"
        :on-click="replaceText"
        v-if="showCannedModal"
      />
      <emoji-input v-on-clickaway="hideEmojiPicker" :on-click="emojiOnClick" v-if="showEmojiPicker"/>
      <textarea
        rows="1"
        v-model="message"
        class="input"
        type="text"
        @click="onClick()"
        @blur="onBlur()"
        v-bind:placeholder="$t(messagePlaceHolder())"
        ref="messageInput"
      />
      <i class="icon ion-happy-outline" :class="{ active: showEmojiPicker}" @click="toggleEmojiPicker()"></i>
    </div>

    <div class="reply-box__bottom" >
      <ul class="tabs">
        <li class="tabs-title" v-bind:class="{ 'is-active': !private }">
          <a href="#" @click="makeReply" >Reply</a>
        </li>
        <li class="tabs-title is-private" v-bind:class="{ 'is-active': private }">
          <a href="#" @click="makePrivate">Private Note</a>
        </li>
        <li class="tabs-title message-length" v-if="message.length">
          <a :class="{ 'message-error': message.length > 620 }">{{ message.length }} / 640</a>
        </li>
      </ul>
      <button
        @click="sendMessage"
        type="button"
        class="button send-button"
        :disabled="disableButton()"
        v-bind:class="{ 'disabled': message.length === 0 || message.length > 640,
                        'warning': private }"
      >
        {{ private ? $t('CONVERSATION.REPLYBOX.CREATE') : $t('CONVERSATION.REPLYBOX.SEND') }}
        <i class="icon" :class="{ 'ion-android-send': !private, 'ion-android-lock': private }"></i>
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
      private: false,
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
  mounted() {
    /* eslint-disable no-confusing-arrow */
    document.addEventListener('keydown', (e) => {
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
  watch: {
    message(val) {
      if (this.private) {
        return;
      }
      const isSlashCommand = val[0] === '/';
      const hasNextWord = val.indexOf(' ') > -1;
      const isShortCodeActive = isSlashCommand && !hasNextWord;
      if (isShortCodeActive) {
        this.showCannedModal = true;
        if (val.length > 1) {
          const searchKey = val.substr(1, val.length);
          this.$store.dispatch('searchCannedResponse', {
            searchKey,
          });
        } else {
          this.$store.dispatch('fetchCannedResponse');
        }
      } else {
        this.showCannedModal = false;
      }
    },
  },
  methods: {
    isEnter(e) {
      return e.keyCode === 13;
    },
    isEscape(e) {
      return e.keyCode === 27;  // ESCAPE
    },
    sendMessage() {
      const messageHasOnlyNewLines = !this.message.replace(/\n/g, '').length;
      if (messageHasOnlyNewLines) {
        return;
      }
      const messageAction = this.private ? 'addPrivateNote' : 'sendMessage';
      if (this.message.length !== 0 && !this.showCannedModal) {
        this.$store.dispatch(messageAction, [this.currentChat.id, this.message]).then(() => {
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
      this.private = true;
      this.$refs.messageInput.focus();
    },
    makeReply() {
      this.private = false;
      this.$refs.messageInput.focus();
    },
    emojiOnClick(emoji) {
      this.message = emojione.shortnameToUnicode(`${this.message}${emoji.shortname} `);
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
        senderId: this.currentChat.meta.sender.id,
      });
    },

    toggleTyping(flag) {
      this.$store.dispatch('toggleTyping', {
        flag,
        inboxId: this.currentChat.inbox_id,
        senderId: this.currentChat.meta.sender.id,
      });
    },
    disableButton() {
      const messageHasOnlyNewLines = !this.message.replace(/\n/g, '').length;
      return this.message.length === 0 || this.message.length > 640 || messageHasOnlyNewLines;
    },

    messagePlaceHolder() {
      const placeHolder = this.private ? 'CONVERSATION.FOOTER.PRIVATE_MSG_INPUT' : 'CONVERSATION.FOOTER.MSG_INPUT';
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
