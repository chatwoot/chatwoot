<script setup>
import { computed } from 'vue';
import {
  REPLY_EDITOR_MODES,
  CHAR_LENGTH_WARNING,
} from 'dashboard/components/widgets/WootWriter/constants';
import EditorModeToggle from 'dashboard/components/widgets/WootWriter/EditorModeToggle.vue';

const props = defineProps({
  mode: {
    type: String,
    default: REPLY_EDITOR_MODES.REPLY,
  },
  isReplyRestricted: {
    type: Boolean,
    default: false,
  },
  isMessageLengthReachingThreshold: {
    type: Boolean,
    default: false,
  },
  charactersRemaining: {
    type: Number,
    default: 0,
  },
});

const emit = defineEmits(['setReplyMode']);

const charLengthClass = computed(() => {
  return props.charactersRemaining < 0 ? 'text-n-ruby-9' : 'text-n-slate-11';
});

const characterLengthWarning = computed(() => {
  return props.charactersRemaining < 0
    ? `${-props.charactersRemaining} ${CHAR_LENGTH_WARNING.NEGATIVE}`
    : `${props.charactersRemaining} ${CHAR_LENGTH_WARNING.UNDER_50}`;
});

const handleModeToggle = () => {
  const newMode =
    props.mode === REPLY_EDITOR_MODES.REPLY
      ? REPLY_EDITOR_MODES.NOTE
      : REPLY_EDITOR_MODES.REPLY;
  emit('setReplyMode', newMode);
};
</script>

<template>
  <div class="flex justify-between items-center h-[3.25rem] gap-2 px-3">
    <div class="flex items-center flex-1">
      <div v-if="isMessageLengthReachingThreshold" class="text-xs">
        <span :class="charLengthClass">
          {{ characterLengthWarning }}
        </span>
      </div>
    </div>
    <EditorModeToggle
      :mode="mode"
      :disabled="isReplyRestricted"
      icon-only
      @toggle-mode="handleModeToggle"
    />
  </div>
</template>
