<script setup>
import { computed, useTemplateRef } from 'vue';
import { useElementSize } from '@vueuse/core';
import { REPLY_EDITOR_MODES } from './constants';

const props = defineProps({
  mode: {
    type: String,
    default: REPLY_EDITOR_MODES.REPLY,
  },
});

defineEmits(['toggleMode']);

const wootEditorReplyMode = useTemplateRef('wootEditorReplyMode');
const wootEditorPrivateMode = useTemplateRef('wootEditorPrivateMode');

const replyModeSize = useElementSize(wootEditorReplyMode);
const privateModeSize = useElementSize(wootEditorPrivateMode);

/**
 * Computed boolean indicating if the editor is in private note mode
 * @type {ComputedRef<boolean>}
 */
const isPrivate = computed(() => props.mode === REPLY_EDITOR_MODES.NOTE);

/**
 * Computes the width of the sliding background chip in pixels
 * Includes 16px of padding in the calculation
 * @type {ComputedRef<string>}
 */
const width = computed(() => {
  const widthToUse = isPrivate.value
    ? privateModeSize.width.value
    : replyModeSize.width.value;

  const widthWithPadding = widthToUse + 16;
  return `${widthWithPadding}px`;
});

/**
 * Computes the X translation value for the sliding background chip
 * Translates by the width of reply mode + padding when in private mode
 * @type {ComputedRef<string>}
 */
const translateValue = computed(() => {
  const xTranslate = isPrivate.value ? replyModeSize.width.value + 16 : 0;

  return `${xTranslate}px`;
});
</script>

<template>
  <button
    class="flex items-center w-auto h-8 p-1 transition-all border rounded-full bg-n-alpha-2 group relative duration-300 ease-in-out z-0"
    @click="$emit('toggleMode')"
  >
    <div ref="wootEditorReplyMode" class="flex items-center gap-1 px-2 z-20">
      {{ $t('CONVERSATION.REPLYBOX.REPLY') }}
    </div>
    <div ref="wootEditorPrivateMode" class="flex items-center gap-1 px-2 z-20">
      {{ $t('CONVERSATION.REPLYBOX.PRIVATE_NOTE') }}
    </div>
    <div
      class="absolute shadow-sm rounded-full h-6 w-[var(--chip-width)] transition-all duration-300 ease-in-out translate-x-[var(--translate-x)] rtl:translate-x-[var(--rtl-translate-x)] bg-n-solid-1"
      :style="{
        '--chip-width': width,
        '--translate-x': translateValue,
        '--rtl-translate-x': `calc(-1 * var(--translate-x))`,
      }"
    />
  </button>
</template>
