<script setup>
import { ref, computed } from 'vue';
import { CSAT_RATINGS, CSAT_DISPLAY_TYPES } from 'shared/constants/messages';

const props = defineProps({
  selected: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update']);

const selectionClass = computed(() => {
  return props.selected
    ? 'outline-n-brand bg-n-brand/5'
    : 'outline-n-weak bg-n-alpha-black2';
});

const emojis = CSAT_RATINGS;
const selectedEmoji = ref(5);
</script>

<template>
  <button
    class="flex items-center rounded-lg transition-all duration-500 cursor-pointer outline outline-1 px-4 py-2 gap-2 min-w-56"
    :class="selectionClass"
    @click="emit('update', CSAT_DISPLAY_TYPES.EMOJI)"
  >
    <div
      v-for="emoji in emojis"
      :key="emoji.key"
      class="rounded-full p-1 transition-transform duration-150 focus:outline-none flex items-center flex-shrink-0"
    >
      <span
        class="text-2xl"
        :class="selectedEmoji === emoji.value ? '' : 'grayscale opacity-60'"
      >
        {{ emoji.emoji }}
      </span>
    </div>
  </button>
</template>
