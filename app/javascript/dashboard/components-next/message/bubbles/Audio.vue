<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import AudioChip from 'next/message/chips/Audio.vue';
import { useMessageContext } from '../provider.js';
import { MESSAGE_VARIANTS } from '../constants';

const { attachments, variant } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

// The audio chip carries its own card, so the bubble behind it is normally
// invisible. A private note is the exception: the amber background is what
// marks it as internal, so it has to stay.
const isPrivate = computed(() => variant.value === MESSAGE_VARIANTS.PRIVATE);
</script>

<template>
  <BaseBubble
    :class="isPrivate ? 'p-2' : 'bg-transparent'"
    data-bubble-name="audio"
  >
    <AudioChip
      :attachment="attachment"
      class="p-2 text-n-slate-12 skip-context-menu"
    />
  </BaseBubble>
</template>
