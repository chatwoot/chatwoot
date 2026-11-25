<script setup>
import { CSAT_RATINGS } from 'shared/constants/messages';

const props = defineProps({
  selectedRating: {
    type: Number,
    default: null,
  },
  isDisabled: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['selectRating']);

const ratings = CSAT_RATINGS;

// Hover effects are gated behind `(hover: hover)`. A touch device keeps :hover on the last
// element tapped, so an unselected face would sit there enlarged and coloured, lying about the
// state -- the reason the old always-on hover scale had to go.
const buttonClass = rating => [
  'flex h-14 w-14 items-center justify-center rounded-full text-4xl',
  'transition-all duration-200 ease-out sm:h-16 sm:w-16 sm:text-5xl',
  'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2',
  'focus-visible:ring-[color:var(--survey-brand)]',
  'disabled:cursor-default disabled:opacity-40',
  '[@media(hover:hover)]:hover:enabled:scale-110',
  '[@media(hover:hover)]:hover:enabled:opacity-100',
  '[@media(hover:hover)]:hover:enabled:saturate-100',
  rating.value === props.selectedRating
    ? 'scale-110 opacity-100 saturate-100 bg-[color-mix(in_srgb,var(--survey-brand)_14%,transparent)]'
    : 'opacity-60 saturate-50',
];
</script>

<template>
  <div class="flex flex-wrap gap-1 pb-2 sm:gap-2">
    <button
      v-for="rating in ratings"
      :key="rating.key"
      type="button"
      :disabled="isDisabled"
      :aria-label="$t(rating.translationKey)"
      :aria-pressed="rating.value === selectedRating"
      :class="buttonClass(rating)"
      @click="emit('selectRating', rating.value)"
    >
      <!-- The label above already says "Good"; without this a screen reader would read the
           glyph name on top of it. -->
      <span aria-hidden="true">{{ rating.emoji }}</span>
    </button>
  </div>
</template>
