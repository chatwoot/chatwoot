<script setup>
import { CSAT_DISPLAY_TYPES } from 'shared/constants/messages';
import CSATEmojiInput from './CSATEmojiInput.vue';
import CSATStarInput from './CSATStarInput.vue';

const props = defineProps({
  selectedType: {
    type: String,
    default: CSAT_DISPLAY_TYPES.EMOJI,
  },
});
const emit = defineEmits(['update']);
</script>

<template>
  <div class="flex flex-wrap gap-6 mt-2">
    <CSATEmojiInput
      :selected="props.selectedType === CSAT_DISPLAY_TYPES.EMOJI"
      @update="emit('update', $event)"
    />
    <CSATStarInput
      :selected="props.selectedType === CSAT_DISPLAY_TYPES.STAR"
      @update="emit('update', $event)"
    />
  </div>
</template>
