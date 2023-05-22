<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOptions"
      class="no-margin"
      :options="options"
      track-by="id"
      label="name"
      :multiple="true"
      :close-on-select="false"
      :clear-on-select="false"
      :hide-selected="true"
      :placeholder="$t('CSAT_REPORTS.FILTERS.AGENTS.PLACEHOLDER')"
      selected-label
      :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
      :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
      @input="handleInput"
    />
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

export default {
  name: 'ReportsFiltersAgents',
  data() {
    return {
      selectedOptions: [],
    };
  },
  computed: {
    ...mapGetters({
      options: 'agents/getAgents',
    }),
  },
  mounted() {
    this.$store.dispatch('agents/get');
  },
  methods: {
    handleInput() {
      this.$emit('agents-filter-selection', this.selectedOptions);
    },
  },
};
</script>
