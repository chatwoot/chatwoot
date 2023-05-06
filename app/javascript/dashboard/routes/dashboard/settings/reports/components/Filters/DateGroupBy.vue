<template>
  <div class="multiselect-wrap--small">
    <p aria-hidden="true" class="hide">
      {{ $t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL') }}
    </p>
    <multiselect
      v-model="currentSelectedFilter"
      class="no-margin"
      track-by="id"
      label="groupBy"
      :placeholder="$t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL')"
      :options="translatedOptions"
      :allow-empty="false"
      :show-labels="false"
      @select="changeFilterSelection"
    />
  </div>
</template>

<script>
import { GROUP_BY_OPTIONS } from '../../constants';

const EVENT_NAME = 'on-grouping-change';

export default {
  name: 'ReportsFiltersDateGroupBy',
  props: {
    validGroupOptions: {
      type: String,
      default: () => [GROUP_BY_OPTIONS.DAY],
    },
  },
  data() {
    return {
      currentSelectedFilter: {
        ...GROUP_BY_OPTIONS.DAY,
        groupBy: this.$t(GROUP_BY_OPTIONS.DAY.translationKey),
      },
    };
  },
  computed: {
    translatedOptions() {
      return this.validGroupOptions.map(option => ({
        ...option,
        groupBy: this.$t(option.translationKey),
      }));
    },
  },
  methods: {
    changeFilterSelection(selectedFilter) {
      this.currentSelectedFilter = selectedFilter;
      this.groupByOptions = this.$emit(EVENT_NAME, selectedFilter);
    },
  },
};
</script>

<style></style>
