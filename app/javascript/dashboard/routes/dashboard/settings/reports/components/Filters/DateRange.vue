<script>
import { DATE_RANGE_OPTIONS } from '../../constants';

const EVENT_NAME = 'on-range-change';

export default {
  name: 'ReportFiltersDateRange',
  data() {
    const translatedOptions = Object.values(DATE_RANGE_OPTIONS).map(option => ({
      ...option,
      name: this.$t(option.translationKey),
    }));

    return {
      // relies on translations, need to move it to constants
      selectedOption: translatedOptions[0],
      options: translatedOptions,
    };
  },
  methods: {
    updateRange(selectedRange) {
      this.selectedOption = selectedRange;
      this.$emit(EVENT_NAME, selectedRange);
    },
  },
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      track-by="name"
      label="name"
      :placeholder="$t('FORMS.MULTISELECT.SELECT_ONE')"
      selected-label
      :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
      deselect-label=""
      :options="options"
      :searchable="false"
      :allow-empty="false"
      @select="updateRange"
    />
  </div>
</template>
