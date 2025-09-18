<script setup>
import { computed, useTemplateRef } from 'vue';
import { useElementSize } from '@vueuse/core';
import { REPLY_EDITOR_MODES } from './constants';

const props = defineProps({
  mode: {
    type: String,
    default: REPLY_EDITOR_MODES.REPLY,
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update:mode', 'toggleMode']);

const wootEditorReplyMode = useTemplateRef('wootEditorReplyMode');
const wootEditorPrivateMode = useTemplateRef('wootEditorPrivateMode');
const wootEditorAiFeedbackMode = useTemplateRef('wootEditorAiFeedbackMode');

const replyModeSize = useElementSize(wootEditorReplyMode);
const privateModeSize = useElementSize(wootEditorPrivateMode);
const aiFeedbackModeSize = useElementSize(wootEditorAiFeedbackMode);

/**
 * Handle mode click
 */
const handleModeClick = mode => {
  emit('update:mode', mode);
};

/**
 * Computed boolean indicating if the editor is in private note mode
 * When disabled, always show NOTE mode regardless of actual mode prop
 * @type {ComputedRef<boolean>}
 */
const isPrivate = computed(() => {
  return props.disabled || props.mode === REPLY_EDITOR_MODES.NOTE;
});

/**
 * Computed boolean indicating if the editor is in AI feedback mode
 * @type {ComputedRef<boolean>}
 */
const isAiFeedback = computed(
  () => props.mode === REPLY_EDITOR_MODES.AI_FEEDBACK
);

/**
 * Computes the width of the sliding background chip in pixels
 * Includes 16px of padding in the calculation
 * @type {ComputedRef<string>}
 */
const width = computed(() => {
  let widthToUse = replyModeSize.width.value;

  if (isAiFeedback.value) {
    widthToUse = aiFeedbackModeSize.width.value;
  } else if (isPrivate.value) {
    widthToUse = privateModeSize.width.value;
  }

  const widthWithPadding = widthToUse + 16;
  return `${widthWithPadding}px`;
});

/**
 * Computes the X translation value for the sliding background chip
 * Translates based on the current mode position
 * @type {ComputedRef<string>}
 */
const translateValue = computed(() => {
  let xTranslate = 0;

  if (isAiFeedback.value) {
    // AI Feedback: Move past Reply + Private Note modes
    xTranslate =
      replyModeSize.width.value + 16 + privateModeSize.width.value + 16;
  } else if (isPrivate.value) {
    // Private Note: Move past Reply mode
    xTranslate = replyModeSize.width.value + 16;
  }
  // Reply mode: xTranslate = 0

  return `${xTranslate}px`;
});
</script>

<template>
  <button
    class="flex items-center w-auto h-8 p-1 transition-all border rounded-full bg-n-alpha-2 group relative duration-300 ease-in-out z-0"
    :disabled="disabled"
    :class="{
      'cursor-not-allowed': disabled,
    }"
    @click="$emit('toggleMode')"
  >
    <button
      ref="wootEditorReplyMode"
      class="flex items-center gap-1 px-2 z-20 cursor-pointer"
      @click="() => handleModeClick(REPLY_EDITOR_MODES.REPLY)"
    >
      {{ $t('CONVERSATION.REPLYBOX.REPLY') }}
    </button>
    <button
      ref="wootEditorPrivateMode"
      class="flex items-center gap-1 px-2 z-20 cursor-pointer"
      @click="() => handleModeClick(REPLY_EDITOR_MODES.NOTE)"
    >
      {{ $t('CONVERSATION.REPLYBOX.PRIVATE_NOTE') }}
    </button>
    <button
      ref="wootEditorAiFeedbackMode"
      class="flex items-center gap-1 px-2 z-20 cursor-pointer"
      @click="() => handleModeClick(REPLY_EDITOR_MODES.AI_FEEDBACK)"
    >
      {{ $t('CONVERSATION.REPLYBOX.AI_FEEDBACK_MODE') }}
    </button>
    <div
      class="absolute shadow-sm rounded-full h-6 w-[var(--chip-width)] ease-in-out translate-x-[var(--translate-x)] rtl:translate-x-[var(--rtl-translate-x)] bg-n-solid-1"
      :class="{
        'transition-all duration-300': !disabled,
      }"
      :style="{
        '--chip-width': width,
        '--translate-x': translateValue,
        '--rtl-translate-x': `calc(-1 * var(--translate-x))`,
      }"
    />
  </button>
</template>
