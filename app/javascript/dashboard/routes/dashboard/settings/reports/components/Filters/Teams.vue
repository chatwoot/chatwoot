<script>
import { mapGetters } from 'vuex';

export default {
  name: 'ReportsFiltersTeams',
  emits: ['teamFilterSelection'],
  data() {
    return {
      selectedOption: null,
    };
  },
  computed: {
    ...mapGetters({
      options: 'teams/getTeams',
    }),
  },
  mounted() {
    this.$store.dispatch('teams/get');
  },
  methods: {
    handleInput() {
      this.$emit('teamFilterSelection', this.selectedOption);
    },
  },
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      :placeholder="$t('TEAM_REPORTS.FILTER_DROPDOWN_LABEL')"
      label="name"
      track-by="id"
      :options="options"
      :option-height="24"
      :show-labels="false"
      @update:model-value="handleInput"
    />
  </div>
</template>
