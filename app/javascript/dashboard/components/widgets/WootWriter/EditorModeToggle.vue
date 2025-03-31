<script setup>
import { computed, useTemplateRef } from 'vue';
import { useElementSize } from '@vueuse/core';
import { REPLY_EDITOR_MODES } from './constants';

const props = defineProps({
  mode: {
    type: String,
    default: REPLY_EDITOR_MODES.REPLY,
  },
  canReplyByCustomMessage: {
    type: Boolean,
    default: () => false,
  },
});

defineEmits(['toggleMode']);

const wootEditorReplyMode = useTemplateRef('wootEditorReplyMode');
const wootEditorPrivateMode = useTemplateRef('wootEditorPrivateMode');
const wootEditorTemplateMode = useTemplateRef('wootEditorTemplateMode');

const replyModeSize = useElementSize(wootEditorReplyMode);
const privateModeSize = useElementSize(wootEditorPrivateMode);
const templateModeSize = useElementSize(wootEditorTemplateMode);

/**
 * Computed boolean indicating if the editor is in private note mode
 * @type {ComputedRef<boolean>}
 */
const isPrivate = computed(() => props.mode === REPLY_EDITOR_MODES.NOTE);
const isTemplate = computed(() => props.mode === REPLY_EDITOR_MODES.TEMPLATE);

/**
 * Computes the width of the sliding background chip in pixels
 * Includes 16px of padding in the calculation
 * @type {ComputedRef<string>}
 */
const width = computed(() => {
  let widthToUse;

  if (isTemplate.value) {
    widthToUse = templateModeSize.width.value;
  } else if (isPrivate.value) {
    widthToUse = privateModeSize.width.value;
  } else {
    widthToUse = replyModeSize.width.value;
  }

  return `${widthToUse + 16}px`;
});

/**
 * Computes the X translation value for the sliding background chip
 * Translates by the width of reply mode + padding when in private mode
 * @type {ComputedRef<string>}
 */
const translateValue = computed(() => {
  if (isTemplate.value) {
    return `0px`;
  }
  if (isPrivate.value) {
    return props.canReplyByCustomMessage
      ? `${replyModeSize.width.value + 16}px` // Reply → Note
      : `${templateModeSize.width.value + 16}px`; // Template → Note
  }
  return `0px`;
});
</script>

<template>
  <button
    class="flex items-center w-auto h-8 p-1 transition-all border rounded-full bg-n-alpha-2 group relative duration-300 ease-in-out z-0"
    @click="$emit('toggleMode')"
  >
    <div ref="wootEditorReplyMode" v-if="canReplyByCustomMessage" class="flex items-center gap-1 px-2 z-20">
      {{ $t('CONVERSATION.REPLYBOX.REPLY') }}
    </div>
    <div ref="wootEditorTemplateMode" v-if="!canReplyByCustomMessage" class="flex items-center gap-1 px-2 z-20">
      {{ $t('CONVERSATION.REPLYBOX.TEMPLATE') }}
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
