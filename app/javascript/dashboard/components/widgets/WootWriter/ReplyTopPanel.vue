<script>
import { useKeyboardEvents } from 'dashboard/composables/useKeyboardEvents';
import { REPLY_EDITOR_MODES, CHAR_LENGTH_WARNING } from './constants';
import NextButton from 'dashboard/components-next/button/Button.vue';
import EditorModeToggle from './EditorModeToggle.vue';

export default {
  name: 'ReplyTopPanel',
  components: {
    NextButton,
    EditorModeToggle,
  },
  props: {
    mode: {
      type: String,
      default: REPLY_EDITOR_MODES.REPLY,
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
  emits: ['setReplyMode', 'togglePopout'],
  setup(props, { emit }) {
    const setReplyMode = mode => {
      emit('setReplyMode', mode);
    };
    const handleReplyClick = () => {
      setReplyMode(REPLY_EDITOR_MODES.REPLY);
    };
    const handleNoteClick = () => {
      setReplyMode(REPLY_EDITOR_MODES.NOTE);
    };
    const handleModeToggle = () => {
      const newMode =
        props.mode === REPLY_EDITOR_MODES.REPLY
          ? REPLY_EDITOR_MODES.NOTE
          : REPLY_EDITOR_MODES.REPLY;
      setReplyMode(newMode);
    };
    const keyboardEvents = {
      'Alt+KeyP': {
        action: () => handleNoteClick(),
        allowOnFocusedInput: true,
      },
      'Alt+KeyL': {
        action: () => handleReplyClick(),
        allowOnFocusedInput: true,
      },
    };
    useKeyboardEvents(keyboardEvents);

    return {
      handleModeToggle,
      handleReplyClick,
      handleNoteClick,
      REPLY_EDITOR_MODES,
    };
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
};
</script>

<template>
  <div class="flex justify-between h-[3.25rem] gap-2 ltr:pl-3 rtl:pr-3">
    <EditorModeToggle
      :mode="mode"
      class="mt-3"
      @toggle-mode="handleModeToggle"
    />
    <div class="flex items-center mx-4 my-0">
      <div v-if="isMessageLengthReachingThreshold" class="text-xs">
        <span :class="charLengthClass">
          {{ characterLengthWarning }}
        </span>
      </div>
    </div>
    <NextButton
      ghost
      class="ltr:rounded-bl-md rtl:rounded-br-md ltr:rounded-br-none rtl:rounded-bl-none ltr:rounded-tl-none rtl:rounded-tr-none text-n-slate-11 ltr:rounded-tr-[11px] rtl:rounded-tl-[11px]"
      icon="i-lucide-maximize-2"
      @click="$emit('togglePopout')"
    />
  </div>
</template>
