<template>
  <div class="bg-black-50 flex justify-between dark:bg-slate-800">
    <div class="mode-wrap flex border-0 p-0 m-0">
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
    <div class="flex items-center my-0 mx-4">
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
import {
  hasPressedAltAndPKey,
  hasPressedAltAndLKey,
} from 'shared/helpers/KeyboardHelpers';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
export default {
  name: 'ReplyTopPanel',
  mixins: [eventListenerMixins],
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
    handleKeyEvents(e) {
      if (hasPressedAltAndPKey(e)) {
        this.handleNoteClick();
      }
      if (hasPressedAltAndLKey(e)) {
        this.handleReplyClick();
      }
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
.button--reply {
  border-width: 0 1px 1px 0 !important;
  @apply border-slate-50 dark:border-slate-700 rounded-none relative z-10;

  &.is-active {
    border-bottom-color: transparent;
    @apply bg-white dark:bg-slate-900;
  }
}

.button--note {
  border-width: 0 0 1px 0 !important;
  @apply text-yellow-700 dark:text-yellow-700 border-slate-50 dark:border-slate-700 rounded-none relative z-10;

  &.is-active {
    border-right-width: 1px !important;
    border-bottom-color: transparent;
    @apply bg-yellow-50 dark:bg-yellow-50;
  }
}
</style>
