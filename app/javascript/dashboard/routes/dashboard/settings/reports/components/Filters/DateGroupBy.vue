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
  computed: {
    translatedOptions() {
      const translations = {
        HOUR: this.$t('REPORT.GROUPING_OPTIONS.HOUR'),
        DAY: this.$t('REPORT.GROUPING_OPTIONS.DAY'),
        WEEK: this.$t('REPORT.GROUPING_OPTIONS.WEEK'),
        MONTH: this.$t('REPORT.GROUPING_OPTIONS.MONTH'),
        YEAR: this.$t('REPORT.GROUPING_OPTIONS.YEAR'),
      };
      return this.validGroupOptions.map(o => ({
        ...o,
        groupBy: translations[o.id] || o.id,
      }));
    },
    currentId: {
      get() {
        return this.selectedOption?.id;
      },
      set(id) {
        const found = this.translatedOptions.find(o => o.id === id);
        if (found) this.$emit('onGroupingChange', found);
      },
    },
  },
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <select v-model="currentId" class="no-margin">
      <option v-for="o in translatedOptions" :key="o.id" :value="o.id">
        {{ o.groupBy }}
      </option>
    </select>
  </div>
</template>
