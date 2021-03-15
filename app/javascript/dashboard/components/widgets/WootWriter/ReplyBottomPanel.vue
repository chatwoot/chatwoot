<template>
  <div class="bottom-box" :class="wrapClass">
    <div class="left-wrap">
      <button
        class="button clear button--emoji"
        :title="$t('CONVERSATION.REPLYBOX.TIP_EMOJI_ICON')"
        @click="toggleEmojiPicker"
      >
        <emoji-or-icon icon="ion-happy-outline" emoji="😊" />
      </button>
      <button
        v-if="showAttachButton"
        class="button clear button--emoji button--upload"
        :title="$t('CONVERSATION.REPLYBOX.TIP_ATTACH_ICON')"
      >
        <file-upload
          :size="4096 * 4096"
          accept="image/*, application/pdf, audio/mpeg, video/mp4, audio/ogg, text/csv"
          @input-file="onFileUpload"
        >
          <emoji-or-icon icon="ion-android-attach" emoji="📎" />
        </file-upload>
      </button>
      <button
        v-if="enableRichEditor && !isOnPrivateNote"
        class="button clear button--emoji"
        :title="$t('CONVERSATION.REPLYBOX.TIP_FORMAT_ICON')"
        @click="toggleFormatMode"
      >
        <emoji-or-icon icon="ion-quote" emoji="🖊️" />
      </button>
    </div>
    <div class="right-wrap">
      <div v-if="isFormatMode" class="enter-to-send--checkbox">
        <input
          :checked="enterToSendEnabled"
          type="checkbox"
          value="enterToSend"
          @input="toggleEnterToSend"
        />
        <label for="enterToSend">
          {{ $t('CONVERSATION.REPLYBOX.ENTER_TO_SEND') }}
        </label>
      </div>
      <button
        class="button nice primary button--send"
        :class="buttonClass"
        @click="onSend"
      >
        {{ sendButtonText }}
      </button>
    </div>
  </div>
</template>

<script>
import FileUpload from 'vue-upload-component';
import EmojiOrIcon from 'shared/components/EmojiOrIcon';

import { REPLY_EDITOR_MODES } from './constants';
export default {
  name: 'ReplyTopPanel',
  components: { EmojiOrIcon, FileUpload },
  props: {
    mode: {
      type: String,
      default: REPLY_EDITOR_MODES.REPLY,
    },
    onSend: {
      type: Function,
      default: () => {},
    },
    sendButtonText: {
      type: String,
      default: '',
    },
    showFileUpload: {
      type: Boolean,
      default: false,
    },
    onFileUpload: {
      type: Function,
      default: () => {},
    },
    showEmojiPicker: {
      type: Boolean,
      default: false,
    },
    toggleEmojiPicker: {
      type: Function,
      default: () => {},
    },
    isSendDisabled: {
      type: Boolean,
      default: false,
    },
    setFormatMode: {
      type: Function,
      default: () => {},
    },
    isFormatMode: {
      type: Boolean,
      default: false,
    },
    isOnPrivateNote: {
      type: Boolean,
      default: false,
    },
    enableRichEditor: {
      type: Boolean,
      default: false,
    },
    enterToSendEnabled: {
      type: Boolean,
      default: true,
    },
  },
  computed: {
    isNote() {
      return this.mode === REPLY_EDITOR_MODES.NOTE;
    },
    wrapClass() {
      return {
        'is-note-mode': this.isNote,
      };
    },
    buttonClass() {
      return {
        'button--note': this.isNote,
        'button--disabled': this.isSendDisabled,
      };
    },
    showAttachButton() {
      return this.showFileUpload || this.isNote;
    },
  },
  methods: {
    toggleFormatMode() {
      this.setFormatMode(!this.isFormatMode);
    },
    toggleEnterToSend() {
      this.$emit('toggleEnterToSend', !this.enterToSendEnabled);
    },
  },
};
</script>

<style lang="scss" scoped>
@import '~widget/assets/scss/variables.scss';
@import '~widget/assets/scss/mixins.scss';

.bottom-box {
  display: flex;
  justify-content: space-between;
  padding: var(--space-slab) var(--space-normal);

  &.is-note-mode {
    background: var(--y-50);
  }
}

.button {
  &.button--emoji {
    margin-right: var(--space-small);
  }

  &.is-active {
    background: white;
  }

  &.button--note {
    background: var(--y-800);
    color: white;

    &:hover {
      background: var(--y-700);
    }
  }

  &.button--disabled {
    background: var(--b-100);
    color: var(--b-400);
    cursor: default;

    &:hover {
      background: var(--b-100);
    }
  }
}

.bottom-box.is-note-mode {
  .button--emoji {
    background: white;
  }
}

.left-wrap {
  align-items: center;
  display: flex;
}

.button--reply {
  border-right: 1px solid var(--color-border-light);
}

.icon--font {
  color: var(--s-600);
  font-size: var(--font-size-default);
}

.right-wrap {
  display: flex;

  .enter-to-send--checkbox {
    align-items: center;
    display: flex;

    input {
      margin: 0;
    }

    label {
      color: var(--s-500);
      font-size: var(--font-size-mini);
    }
  }
}
</style>
