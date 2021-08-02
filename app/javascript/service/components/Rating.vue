<template>
  <div class="customer-satisfcation mb-2">
    <div class="ratings flex py-5 px-0">
      <button
        v-for="rating in ratings"
        :key="rating.key"
        :class="buttonClass(rating)"
        @click="selectRating(rating)"
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
    messageContentAttributes: {
      type: Object,
      default: () => {},
    },
  },
  data() {
    return {
      email: '',
      ratings: CSAT_RATINGS,
      selectedRating: null,
    };
  },
  computed: {
    isRatingSubmitted() {
      return this.messageContentAttributes?.csat_survey_response?.rating;
    },
  },

  methods: {
    buttonClass(rating) {
      return [
        { selected: rating.value === this.selectedRating },
        { disabled: this.isRatingSubmitted },
        { hover: this.isRatingSubmitted },
        'emoji-button shadow-none text-4xl outline-none mr-8',
      ];
    },
    selectRating(rating) {
      this.selectedRating = rating.value;
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
