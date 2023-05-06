<template>
  <div v-if="notLast7Days" class="multiselect-wrap--small">
    <p aria-hidden="true" class="hide">
      {{ $t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL') }}
    </p>
    <multiselect
      v-model="currentSelectedFilter"
      class="no-margin"
      track-by="id"
      label="groupBy"
      :placeholder="$t('REPORT.GROUP_BY_FILTER_DROPDOWN_LABEL')"
      :options="groupByOptions"
      :allow-empty="false"
      :show-labels="false"
      @select="changeFilterSelection"
    />
  </div>
</template>

<script>
import { GROUP_BY_FILTER } from '../../constants';

const EVENT_NAME = 'on-grouping-change';

export default {
  name: 'ReportsFiltersDateGroupBy',
  props: {
    maxGranularity: {
      type: String,
      default: GROUP_BY_FILTER[0],
    },
  },
  data() {
    return {
      currentSelectedFilter: null,
    };
  },
  computed: {
    notLast7Days() {
      return this.maxGranularity !== GROUP_BY_FILTER[1].period;
    },
    groupByOptions() {
      switch (this.maxGranularity) {
        case GROUP_BY_FILTER[2].period:
          return this.$t('REPORT.GROUP_BY_WEEK_OPTIONS');
        case GROUP_BY_FILTER[3].period:
          return this.$t('REPORT.GROUP_BY_MONTH_OPTIONS');
        case GROUP_BY_FILTER[4].period:
          return this.$t('REPORT.GROUP_BY_YEAR_OPTIONS');
        default:
          return this.$t('REPORT.GROUP_BY_DAY_OPTIONS');
      }
    },
  },
  mounted() {
    this.currentSelectedFilter = this.groupByOptions[0];
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
