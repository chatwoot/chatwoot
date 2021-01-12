<template>
  <div class="bottom-box" :class="wrapClass">
    <div class="left-wrap">
      <button class="button clear button--emoji" @click="toggleEmojiPicker">
        <emoji-or-icon icon="ion-happy-outline" emoji="😊" />
      </button>
      <button
        v-if="showAttachButton"
        class="button clear button--emoji button--upload"
      >
        <file-upload
          :size="4096 * 4096"
          accept="image/*, application/pdf, audio/mpeg, video/mp4, audio/ogg, text/csv"
          @input-file="onFileUpload"
        >
          <emoji-or-icon icon="ion-android-attach" emoji="📎" />
        </file-upload>
      </button>
    </div>
    <div class="right-wrap">
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
  font-size: var(--font-size-small);
  font-weight: var(--font-weight-medium);
  padding: var(--space-one) var(--space-slab);
  display: flex;
  align-items: center;
  justify-content: space-between;

  &:hover {
    background: var(--w-300);
  }

  &.is-active {
    background: white;
  }

  &.button--emoji {
    font-size: var(--font-size-small);
    padding: var(--space-small);
    border-radius: 9px;
    background: var(--b-50);
    border: 1px solid var(--color-border-light);
    margin-right: var(--space-small);

    &:hover {
      background: var(--b-200);
    }
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
  display: flex;
  align-items: center;
}

.button--reply {
  border-right: 1px solid var(--color-border-light);
}

.icon--font {
  color: var(--s-600);
  font-size: var(--font-size-default);
}
</style>
