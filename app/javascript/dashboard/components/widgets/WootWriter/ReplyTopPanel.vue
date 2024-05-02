<template>
  <div class="flex justify-between bg-black-50 dark:bg-slate-800">
    <div class="button-group">
      <woot-button
        variant="clear"
        class="button--reply"
        :class="replyButtonClass"
        @click="handleReplyClick"
      >
        {{ $t('CONVERSATION.REPLYBOX.REPLY') }}
      </woot-button>

      <woot-button
        class="button--note"
        variant="clear"
        color-scheme="warning"
        :class="noteButtonClass"
        @click="handleNoteClick"
      >
        {{ $t('CONVERSATION.REPLYBOX.PRIVATE_NOTE') }}
      </woot-button>
    </div>
    <div class="flex items-center mx-4 my-0">
      <div v-if="isMessageLengthReachingThreshold" class="text-xs">
        <span :class="charLengthClass">
          {{ characterLengthWarning }}
        </span>
      </div>
    </div>
    <woot-button
      v-if="popoutReplyBox"
      variant="clear"
      icon="dismiss"
      color-scheme="secondary"
      class-names="popout-button"
      @click="$emit('click')"
    />
    <woot-button
      v-else
      variant="clear"
      icon="resize-large"
      color-scheme="secondary"
      class-names="popout-button"
      @click="$emit('click')"
    />
  </div>
</template>

<script>
import { REPLY_EDITOR_MODES, CHAR_LENGTH_WARNING } from './constants';
import keyboardEventListenerMixins from 'shared/mixins/keyboardEventListenerMixins';
export default {
  name: 'ReplyTopPanel',
  mixins: [keyboardEventListenerMixins],
  props: {
    mode: {
      type: String,
      default: REPLY_EDITOR_MODES.REPLY,
    },
    setReplyMode: {
      type: Function,
      default: () => {},
    },
    isMessageLengthReachingThreshold: {
      type: Boolean,
      default: () => false,
    },
    charactersRemaining: {
      type: Number,
      default: () => 0,
    },
    popoutReplyBox: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    replyButtonClass() {
      return {
        'is-active': this.mode === REPLY_EDITOR_MODES.REPLY,
      };
    },
    noteButtonClass() {
      return {
        'is-active': this.mode === REPLY_EDITOR_MODES.NOTE,
      };
    },
    charLengthClass() {
      return this.charactersRemaining < 0 ? 'text-red-600' : 'text-slate-600';
    },
    characterLengthWarning() {
      return this.charactersRemaining < 0
        ? `${-this.charactersRemaining} ${CHAR_LENGTH_WARNING.NEGATIVE}`
        : `${this.charactersRemaining} ${CHAR_LENGTH_WARNING.UNDER_50}`;
    },
  },
  methods: {
    getKeyboardEvents() {
      return {
        'Alt+KeyP': {
          action: () => this.handleNoteClick(),
          allowOnFocusedInput: true,
        },
        'Alt+KeyL': {
          action: () => this.handleReplyClick(),
          allowOnFocusedInput: true,
        },
      };
    },
    handleReplyClick() {
      this.setReplyMode(REPLY_EDITOR_MODES.REPLY);
    },
    handleNoteClick() {
      this.setReplyMode(REPLY_EDITOR_MODES.NOTE);
    },
  },
};
</script>

<style lang="scss" scoped>
.button-group {
  @apply flex border-0 p-0 m-0;

  .button {
    @apply text-sm font-medium py-2.5 px-4 m-0 relative z-10;
    &.is-active {
      @apply bg-white dark:bg-slate-900;
    }
  }
  .button--reply {
    @apply border-r rounded-none border-b-0 border-l-0 border-t-0 border-slate-50 dark:border-slate-700;
    &:hover,
    &:focus {
      @apply border-r border-slate-50 dark:border-slate-700;
    }
  }
  .button--note {
    @apply border-l-0 rounded-none;
    &.is-active {
      @apply border-r border-b-0 bg-yellow-100 dark:bg-yellow-800 border-t-0 border-slate-50 dark:border-slate-700;
    }
    &:hover,
    &:active {
      @apply text-yellow-700 dark:text-yellow-700;
    }
  }
}
.button--note {
  @apply text-yellow-600 dark:text-yellow-600 bg-transparent dark:bg-transparent;
}
</style>
