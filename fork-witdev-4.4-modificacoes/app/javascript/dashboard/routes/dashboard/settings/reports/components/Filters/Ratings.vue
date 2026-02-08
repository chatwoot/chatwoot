<script>
import { CSAT_RATINGS } from 'shared/constants/messages';

export default {
  name: 'ReportFiltersRatings',
  emits: ['ratingFilterSelection'],
  data() {
    const translatedOptions = CSAT_RATINGS.reverse().map(option => ({
      ...option,
      label: this.$t(option.translationKey),
    }));

    return {
      selectedOption: null,
      options: translatedOptions,
    };
  },
  methods: {
    handleInput(selectedRating) {
      this.$emit('ratingFilterSelection', selectedRating);
    },
  },
};
</script>

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
      label="label"
      @update:model-value="handleInput"
    />
  </div>
</template>
