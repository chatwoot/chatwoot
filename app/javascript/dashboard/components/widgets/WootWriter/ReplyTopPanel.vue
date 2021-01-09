<template>
  <div class="top-box">
    <div class="mode-wrap button-group">
      <button
        class="button clear button--reply"
        :class="replyButtonClass"
        @click="handleReplyClick"
      >
        💬 {{ $t('CONVERSATION.REPLYBOX.REPLY') }}
      </button>

      <button
        class="button clear button--note"
        :class="noteButtonClass"
        @click="handleNoteClick"
      >
        📝 {{ $t('CONVERSATION.REPLYBOX.PRIVATE_NOTE') }}
      </button>
    </div>
    <div class="action-wrap">
      <div v-if="isMessageLengthReachingThreshold" class="tabs-title">
        <a>{{ charactersRemaining }} characters remaining</a>
      </div>
    </div>
  </div>
</template>

<script>
import { REPLY_EDITOR_MODES } from './constants';
export default {
  name: 'ReplyTopPanel',
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
  },
  methods: {
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

  background: var(--b-100);
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
    border-right: 1px solid var(--color-border);

    &:hover {
      border-right: 1px solid var(--color-border);
    }
  }

  .button--note {
    &.is-active {
      border-right: 1px solid var(--color-border);
      background: var(--y-50);
    }
  }
}

.button--note {
  color: var(--y-900);
}

.action-wrap {
  display: flex;
  align-items: center;
  margin: 0 var(--space-normal);
}
</style>
