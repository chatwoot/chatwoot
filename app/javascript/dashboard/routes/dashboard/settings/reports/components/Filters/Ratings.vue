<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      :option-height="24"
      :placeholder="selectRating"
      :options="options"
      :show-labels="false"
      track-by="value"
      label="label"
      @input="handleInput"
      :multiple="multiple"
    />
  </div>
</template>

<script>
import { CSAT_RATINGS } from 'shared/constants/messages';

export default {
  name: 'ReportFiltersRatings',
  props: {
    multiple: {
      type: Boolean,
      default: false,
    }
  },
  data() {
    const translatedOptions = CSAT_RATINGS.reverse().map(option => ({
      ...option,
      label: this.$t(option.translationKey),
    }));

    return {
      selectedOption: null,
      options: translatedOptions,
      selectRating: 'Select CSAT Rating'
    };
  },
  methods: {
    handleInput(selectedRating) {
      this.$emit('rating-filter-selection', selectedRating);
    },
  },
};
</script>
