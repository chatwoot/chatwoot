<script>
import { mapGetters } from 'vuex';

export default {
  name: 'ReportsFiltersTeams',
  props: {
    selectedTeam: {
      type: Array,
      default: () => [],
    },
  },
  emits: ['teamFilterSelection'],
  data() {
    return {
      selectedOptions: this.selectedTeam || [],
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
      this.$emit('teamFilterSelection', this.selectedOptions);
    },
  },
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOptions"
      class="no-margin"
      :options="options"
      track-by="id"
      label="name"
      multiple
      :close-on-select="false"
      :clear-on-select="false"
      hide-selected
      :option-height="24"
      :show-labels="false"
      :placeholder="$t('TEAM_REPORTS.FILTER_DROPDOWN_LABEL')"
      selected-label
      :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
      :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
      @update:model-value="handleInput"
    />
  </div>
</template>
