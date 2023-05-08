<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      :option-height="24"
      :placeholder="$t('FORMS.MULTISELECT.SELECT_ONE')"
      :options="options"
      :show-labels="false"
      track-by="value"
      label="emoji"
      @input="handleInput"
    />
  </div>
</template>

<script>
import { CSAT_RATINGS } from 'shared/constants/messages';

export default {
  name: 'ReportFiltersRatings',
  data() {
    return {
      selectedOption: null,
      options: CSAT_RATINGS,
    };
  },
  methods: {
    handleInput(selectedRating) {
      this.$emit('rating-filter-selection', selectedRating);
    },
  },
};
</script>
