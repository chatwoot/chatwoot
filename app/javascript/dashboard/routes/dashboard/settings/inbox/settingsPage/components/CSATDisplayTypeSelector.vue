<script setup>
import { ref } from 'vue';
import { CSAT_RATINGS, CSAT_DISPLAY_TYPES } from 'shared/constants/messages';

const props = defineProps({
  selectedType: {
    type: String,
    default: CSAT_DISPLAY_TYPES.EMOJI,
  },
});
const emit = defineEmits(['update']);

const emojis = CSAT_RATINGS;
const selectedEmoji = ref(4);
const selectedStar = ref(4);
</script>

<template>
  <div class="flex flex-wrap gap-6 mt-2">
    <div
      class="flex items-center rounded-lg transition-all duration-500 cursor-pointer border px-4 py-2 gap-2 min-w-56"
      :class="
        props.selectedType === CSAT_DISPLAY_TYPES.EMOJI
          ? 'border-n-brand bg-n-brand/5'
          : 'border-n-weak bg-n-alpha-black2'
      "
      @click="emit('update', CSAT_DISPLAY_TYPES.EMOJI)"
    >
      <button
        v-for="(emoji, id) in emojis"
        :key="emoji.key"
        type="button"
        class="rounded-full p-1 transition-transform duration-150 focus:outline-none flex items-center flex-shrink-0"
        :aria-label="emoji.translationKey"
        @click="selectedEmoji = id"
      >
        <span
          class="text-2xl"
          :class="selectedEmoji !== id && 'grayscale opacity-60'"
        >
          {{ emoji.emoji }}
        </span>
      </button>
    </div>
    <div
      class="flex items-center rounded-lg transition-all duration-500 cursor-pointer border px-4 py-2 gap-2 min-w-56"
      :class="
        props.selectedType === CSAT_DISPLAY_TYPES.STAR
          ? 'border-n-brand bg-n-brand/5'
          : 'border-n-weak bg-n-alpha-black2'
      "
      @click="emit('update', CSAT_DISPLAY_TYPES.STAR)"
    >
      <button
        v-for="n in 5"
        :key="'star-' + n"
        type="button"
        class="rounded-full p-1 transition-transform duration-150 focus:outline-none flex items-center flex-shrink-0"
        :aria-label="`Star ${n}`"
        @click="selectedStar = n"
      >
        <i
          :class="
            selectedStar >= n
              ? 'i-ri-star-fill text-n-amber-9 text-2xl'
              : 'i-ri-star-line text-n-slate-10 text-2xl'
          "
        />
      </button>
    </div>
  </div>
</template>
