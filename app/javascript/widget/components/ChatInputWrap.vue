<template>
  <div class="chat-message--input">
    <resizable-text-area
      v-model="userInput"
      :placeholder="$t('CHAT_PLACEHOLDER')"
      class="form-input user-message-input"
      @focus="onFocus"
      @blur="onBlur"
    />
    <div v-if="showCopiedMessage" class="share-link">
      <span>
        Share link copied!
      </span>
    </div>
    <div v-if="!showCopiedMessage" class="button-wrap">
      <chat-attachment-button v-if="showIcon" :on-attach="onSendAttachment" />
      <i
        v-if="websiteURL() && showIcon"
        class="icon ion-link"
        @click="onCopy"
      />
      <emoji-input
        v-if="showEmojiPicker"
        v-on-clickaway="hideEmojiPicker"
        :on-click="emojiOnClick"
      />
      <i
        class="icon ion-happy-outline"
        :class="{ active: showEmojiPicker }"
        @click="toggleEmojiPicker()"
      />
      <chat-send-button
        v-if="showSendButton"
        :on-click="handleButtonClick"
        :color="widgetColor"
      />
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import emojione from 'emojione';
import { mixin as clickaway } from 'vue-clickaway';
import ChatSendButton from 'widget/components/ChatSendButton.vue';
import ChatAttachmentButton from 'widget/components/ChatAttachment.vue';
import ResizableTextArea from 'shared/components/ResizableTextArea';
import EmojiInput from 'dashboard/components/widgets/emoji/EmojiInput';
import copy from 'copy-text-to-clipboard';

export default {
  name: 'ChatInputWrap',
  components: {
    ChatAttachmentButton,
    ChatSendButton,
    EmojiInput,
    ResizableTextArea,
  },
  mixins: [clickaway],
  props: {
    onSendMessage: {
      type: Function,
      default: () => {},
    },
    onSendAttachment: {
      type: Function,
      default: () => {},
    },
  },

  data() {
    return {
      userInput: '',
      showEmojiPicker: false,
      showCopiedMessage: false,
    };
  },

  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    showIcon() {
      return this.userInput.length === 0;
    },
    showSendButton() {
      return this.userInput.length > 0;
    },
  },

  destroyed() {
    document.removeEventListener('keypress', this.handleEnterKeyPress);
  },
  mounted() {
    document.addEventListener('keypress', this.handleEnterKeyPress);
  },

  methods: {
    handleButtonClick() {
      if (this.userInput && this.userInput.trim()) {
        this.onSendMessage(this.userInput);
      }
      this.userInput = '';
    },
    handleEnterKeyPress(e) {
      if (e.keyCode === 13 && !e.shiftKey) {
        e.preventDefault();
        this.handleButtonClick();
      }
    },
    displayCopiedMessage() {
      if (this.showCopiedMessage) {
        return;
      }

      this.showCopiedMessage = true;
      setTimeout(() => {
        this.showCopiedMessage = false;
      }, 3000);
    },
    onCopy(e) {
      e.preventDefault();
      let share_link = window.authToken;

      copy(`${this.websiteURL()}?chatwoot_share_link=${share_link}`);
      this.displayCopiedMessage();
    },
    websiteURL() {
      return window.chatwootWebChannel.websiteURL;
    },
    toggleEmojiPicker() {
      this.showEmojiPicker = !this.showEmojiPicker;
    },
    hideEmojiPicker() {
      if (this.showEmojiPicker) {
        this.toggleEmojiPicker();
      }
    },
    emojiOnClick(emoji) {
      this.userInput = emojione.shortnameToUnicode(
        `${this.userInput}${emoji.shortname} `
      );
    },

    onBlur() {
      this.toggleTyping('off');
    },
    onFocus() {
      this.toggleTyping('on');
    },
    toggleTyping(typingStatus) {
      this.$store.dispatch('conversation/toggleUserTyping', { typingStatus });
    },
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.chat-message--input {
  align-items: center;
  display: flex;
}

.icon {
  font-size: $font-size-large;
  color: $color-gray;
  margin-right: $space-small;
  cursor: pointer;
}

.emoji-dialog {
  right: $space-one;
}

.file-uploads {
  margin-right: $space-small;
}

.button-wrap {
  display: flex;
  align-items: center;
}

.share-link {
  min-width: 13rem;
  font-size: $font-size-default;
}

.user-message-input {
  border: 0;
  height: $space-large;
  min-height: $space-large;
  max-height: 2.4 * $space-mega;
  resize: none;
  padding-top: $space-small;
}
</style>
