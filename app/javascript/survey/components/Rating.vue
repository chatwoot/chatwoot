<template>
  <div class="customer-satisfcation mb-2">
    <div
      v-if="isYesNoFormat"
      class="yes-no-buttons flex gap-4 py-5 px-0 justify-center"
    >
      <button
        v-for="option in yesNoOptions"
        :key="option.key"
        :class="yesNoButtonClass(option)"
        @click="onClick(option)"
      >
        {{ $t(option.translationKey) }}
      </button>
    </div>
    <div v-else class="ratings flex py-5 px-0">
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
import {
  CSAT_RATINGS,
  CSAT_YES_NO_OPTIONS,
  CSAT_FORMATS,
} from 'shared/constants/messages';

export default {
  props: {
    selectedRating: {
      type: Number,
      default: null,
    },
    csatFormat: {
      type: String,
      default: 'emoji_5_scale',
    },
  },
  data() {
    return {
      ratings: CSAT_RATINGS,
      yesNoOptions: CSAT_YES_NO_OPTIONS,
    };
  },
  computed: {
    isYesNoFormat() {
      return this.csatFormat === CSAT_FORMATS.YES_NO;
    },
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
    yesNoButtonClass(option) {
      const isSelected = option.value === this.selectedRating;
      return [
        'yes-no-button',
        'px-8 py-3 rounded-lg font-semibold text-lg transition-all border-2',
        option.key,
        {
          'bg-white': !isSelected,
          'shadow-lg transform scale-110': isSelected,
          'hover:shadow-lg hover:transform hover:scale-105':
            !this.selectedRating,
          'cursor-pointer': !this.selectedRating,
          'cursor-default opacity-60': this.selectedRating,
          disabled: this.selectedRating,
        },
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

.yes-no-button {
  min-width: 120px;

  &.disabled {
    pointer-events: none;
  }

  &.yes {
    border-color: #44ce4b;
    color: #44ce4b;

    &.shadow-lg {
      background-color: #44ce4b;
      color: white;
    }
  }

  &.no {
    border-color: #fdad2a;
    color: #fdad2a;

    &.shadow-lg {
      background-color: #fdad2a;
      color: white;
    }
  }
}
</style>
