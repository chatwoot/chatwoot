<script setup>
import { ref, defineProps, defineEmits } from 'vue';

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

const starRatings = [1, 2, 3, 4, 5];
const hoveredRating = ref(0);

const onHoverRating = value => {
  if (props.isDisabled) return;
  hoveredRating.value = value;
};

const selectRating = value => {
  if (props.isDisabled) return;
  emit('selectRating', value);
};

const getStarClass = value => {
  const isStarActive =
    (hoveredRating.value > 0 &&
      !props.isDisabled &&
      hoveredRating.value >= value) ||
    props.selectedRating >= value;

  const starTypeClass = isStarActive
    ? 'i-ri-star-fill text-n-amber-9'
    : 'i-ri-star-line text-n-slate-10';

  return starTypeClass;
};
</script>

<template>
  <div class="flex justify-center py-5 px-4 gap-3">
    <button
      v-for="value in starRatings"
      :key="value"
      type="button"
      class="rounded-full p-1 transition-all duration-200 focus:enabled:scale-[1.2] focus-within:enabled:scale-[1.2] hover:enabled:scale-[1.2] focus:outline-none flex items-center flex-shrink-0"
      :class="{ 'cursor-not-allowed opacity-50': isDisabled }"
      :disabled="isDisabled"
      :aria-label="'Star ' + value"
      @click="selectRating(value)"
      @mouseenter="onHoverRating(value)"
      @mouseleave="onHoverRating(0)"
    >
      <span
        :class="getStarClass(value)"
        class="transition-all duration-500 text-2xl"
      />
    </button>
  </div>
</template>
