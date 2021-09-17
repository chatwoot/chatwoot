<template>
  <div class="customer-satisfcation mb-2">
    <div class="ratings flex py-5 px-0">
      <button
        v-for="rating in ratings"
        :key="rating.key"
        :class="buttonClass(rating)"
        @click="onClick(rating)"
      >
        {{ rating.emoji }}
      </button>
    </div>
  </div>
</template>

<script>
import { CSAT_RATINGS } from 'shared/constants/messages';

export default {
  props: {
    selectedRating: {
      type: Number,
      default: null,
    },
  },
  data() {
    return {
      ratings: CSAT_RATINGS,
    };
  },

  methods: {
    buttonClass(rating) {
      return [
        { selected: rating.value === this.selectedRating },
        { disabled: !!this.selectedRating },
        { hover: !!this.selectedRating },
        'emoji-button shadow-none text-3xl lg:text-4xl outline-none mr-8',
      ];
    },
    onClick(rating) {
      this.$emit('selectRating', rating.value);
    },
  },
};
</script>

<style lang="scss" scoped>
.emoji-button {
  filter: grayscale(100%);
  &.selected,
  &:hover,
  &:focus,
  &:active {
    filter: grayscale(0%);
    transform: scale(1.32);
    transition: transform 300ms;
  }

  &.disabled {
    cursor: default;
    opacity: 0.5;
    pointer-events: none;
  }
}
</style>
