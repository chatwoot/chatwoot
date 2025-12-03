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

defineEmits(['toggleMode']);

const wootEditorReplyMode = useTemplateRef('wootEditorReplyMode');
const wootEditorPrivateMode = useTemplateRef('wootEditorPrivateMode');

const replyModeSize = useElementSize(wootEditorReplyMode);
const privateModeSize = useElementSize(wootEditorPrivateMode);

/**
 * Computed boolean indicating if the editor is in private note mode
 * When disabled, always show NOTE mode regardless of actual mode prop
 * @type {ComputedRef<boolean>}
 */
const isPrivate = computed(() => {
  return props.disabled || props.mode === REPLY_EDITOR_MODES.NOTE;
});

/**
 * Computes the width of the sliding background chip in pixels
 * Includes 24px of padding in the calculation (px-3 = 12px on each side)
 * @type {ComputedRef<string>}
 */
const width = computed(() => {
  const widthToUse = isPrivate.value
    ? privateModeSize.width.value
    : replyModeSize.width.value;

  const widthWithPadding = widthToUse + 24;
  return `${widthWithPadding}px`;
});

/**
 * Computes the X translation value for the sliding background chip
 * Translates by the width of reply mode + padding (24px) when in private mode
 * @type {ComputedRef<string>}
 */
const translateValue = computed(() => {
  const xTranslate = isPrivate.value ? replyModeSize.width.value + 24 : 0;

  return `${xTranslate}px`;
});
</script>

<template>
  <button
    class="flex items-center w-auto h-8 transition-all border rounded-lg bg-n-input-background group relative duration-300 ease-in-out z-0 active:scale-[0.995] active:duration-75 !p-0"
    :disabled="disabled"
    :class="{
      'cursor-not-allowed': disabled,
    }"
    @click="$emit('toggleMode')"
  >
    <div
      ref="wootEditorReplyMode"
      class="flex items-center gap-1 px-3 z-20"
      :class="{
        'text-n-slate-12': !isPrivate,
        'text-n-slate-10': isPrivate,
      }"
    >
      {{ $t('CONVERSATION.REPLYBOX.REPLY') }}
    </div>
    <div
      ref="wootEditorPrivateMode"
      class="flex items-center gap-1 px-3 z-20"
      :class="{
        'text-n-amber-text': isPrivate,
        'text-n-slate-10': !isPrivate,
      }"
    >
      {{ $t('CONVERSATION.REPLYBOX.PRIVATE_NOTE') }}
    </div>
    <div
      class="absolute shadow-sm rounded-lg h-8 w-[var(--chip-width)] ease-in-out translate-x-[var(--translate-x)] rtl:translate-x-[var(--rtl-translate-x)] outline outline-1 outline-n-container"
      :class="{
        'transition-all duration-300': !disabled,
        'bg-n-surface-active': !isPrivate,
        'bg-n-solid-amber': isPrivate,
      }"
      :style="{
        '--chip-width': width,
        '--translate-x': translateValue,
        '--rtl-translate-x': `calc(-1 * var(--translate-x))`,
      }"
    />
  </button>
</template>
