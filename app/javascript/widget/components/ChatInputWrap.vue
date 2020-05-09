<template>
  <div class="chat-message--input">
    <chat-input-area
      v-model="userInput"
      :placeholder="$t('CHAT_PLACEHOLDER')"
    />
    <div class="button-wrap">
      <chat-attachment-button
        v-if="showAttachment"
        :on-attach="onSendAttachment"
      />
      <emoji-input
        v-if="showEmojiPicker"
        v-on-clickaway="hideEmojiPicker"
        :on-click="emojiOnClick"
      />
      <i
        class="emoji-toggle icon ion-happy-outline"
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
import ChatInputArea from 'widget/components/ChatInputArea.vue';
import EmojiInput from 'dashboard/components/widgets/emoji/EmojiInput';

export default {
  name: 'ChatInputWrap',
  components: {
    ChatAttachmentButton,
    ChatSendButton,
    ChatInputArea,
    EmojiInput,
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
    };
  },

  computed: {
    ...mapGetters({
      widgetColor: 'appConfig/getWidgetColor',
    }),
    showAttachment() {
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
  },
};
</script>

<style scoped lang="scss">
@import '~widget/assets/scss/variables.scss';

.chat-message--input {
  align-items: center;
  display: flex;
}

.emoji-toggle {
  font-size: $font-size-large;
  color: $color-gray;
  padding-right: $space-smaller;
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
</style>
