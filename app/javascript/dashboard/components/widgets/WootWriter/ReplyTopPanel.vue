<template>
  <div class="top-box">
    <div class="mode-wrap button-group">
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
    <div class="action-wrap">
      <div v-if="isMessageLengthReachingThreshold" class="tabs-title">
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
      return this.charactersRemaining < 0 ? 'message-error' : 'message-length';
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
.top-box {
  display: flex;
  justify-content: space-between;

  background: var(--b-50);
}

.button-group {
  border: 0;
  padding: 0;
  margin: 0;

  .button {
    font-size: var(--font-size-small);
    font-weight: var(--font-weight-medium);
    padding: var(--space-one) var(--space-normal);
    margin: 0;
    position: relative;
    z-index: 1;

    &.is-active {
      background: white;
    }
  }

  .button--reply {
    border-radius: 0;
    border-right: 1px solid var(--color-border);

    &:hover,
    &:focus {
      border-right: 1px solid var(--color-border);
    }
  }

  .button--note {
    border-radius: 0;

    &.is-active {
      border-right: 1px solid var(--color-border);
      background: var(--y-50);
    }

    &:hover,
    &:active {
      color: var(--y-700);
    }
  }
}

.button--note {
  color: var(--y-600);
}

.action-wrap {
  display: flex;
  align-items: center;
  margin: 0 var(--space-normal);
  font-size: var(--font-size-mini);

  .message-error {
    color: var(--r-600);
  }
  .message-length {
    color: var(--s-600);
  }
}
</style>
