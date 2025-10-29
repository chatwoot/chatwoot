<script>
import { GROUP_BY_OPTIONS } from '../../constants';

export default {
  name: 'ReportsFiltersDateGroupBy',
  props: {
    validGroupOptions: {
      type: Array,
      default: () => [GROUP_BY_OPTIONS.DAY],
    },
    selectedOption: {
      type: Object,
      default: () => GROUP_BY_OPTIONS.DAY,
    },
  },
  emits: ['onGroupingChange'],
  data() {
    return {
      currentSelectedFilter: null,
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
  watch: {
    selectedOption: {
      handler() {
        this.currentSelectedFilter = {
          ...this.selectedOption,
          groupBy: this.$t(this.selectedOption.translationKey),
        };
      },
      immediate: true,
    },
  },
  methods: {
    changeFilterSelection(selectedFilter) {
      this.groupByOptions = this.$emit('onGroupingChange', selectedFilter);
    },
  },
};
</script>

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
