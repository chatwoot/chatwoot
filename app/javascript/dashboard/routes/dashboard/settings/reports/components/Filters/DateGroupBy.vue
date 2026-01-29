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
    effectiveGroupOptions() {
      return this.validGroupOptions;
    },

    translatedOptions() {
      const translations = {
        HOUR: this.$t('REPORT.GROUPING_OPTIONS.HOUR'),
        DAY: this.$t('REPORT.GROUPING_OPTIONS.DAY'),
        WEEK: this.$t('REPORT.GROUPING_OPTIONS.WEEK'),
        MONTH: this.$t('REPORT.GROUPING_OPTIONS.MONTH'),
        YEAR: this.$t('REPORT.GROUPING_OPTIONS.YEAR'),
      };

      return this.effectiveGroupOptions.map(option => ({
        ...option,
        groupBy: translations[option.id] || option.id,
      }));
    },
  },

  watch: {
    selectedOption: {
      handler(newOption) {
        if (newOption) {
          const translations = {
            HOUR: this.$t('REPORT.GROUPING_OPTIONS.HOUR'),
            DAY: this.$t('REPORT.GROUPING_OPTIONS.DAY'),
            WEEK: this.$t('REPORT.GROUPING_OPTIONS.WEEK'),
            MONTH: this.$t('REPORT.GROUPING_OPTIONS.MONTH'),
            YEAR: this.$t('REPORT.GROUPING_OPTIONS.YEAR'),
          };

          this.currentSelectedFilter = {
            ...newOption,
            groupBy: translations[newOption.id] || newOption.id,
          };
        }
      },
      immediate: true,
    },
  },

  methods: {
    changeFilterSelection(selectedFilter) {
      this.$emit('onGroupingChange', selectedFilter);
    },
  },
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <p aria-hidden="true" class="hidden">
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
