<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      :placeholder="'Select Flow'"
      label="name"
      track-by="id"
      :options="flowOptions"
      :option-height="24"
      :show-labels="false"
      :loading="isLoading"
      @input="handleInput"
    >
      <template slot="singleLabel" slot-scope="props">
        <span class="reports-option__desc">
          <span class="my-0 text-slate-800 dark:text-slate-75">
            {{ props.option.name }}
          </span>
        </span>
      </template>
      <template slot="option" slot-scope="props">
        <span class="reports-option__desc">
          <span class="my-0 text-slate-800 dark:text-slate-75">
            {{ props.option.name }}
          </span>
        </span>
      </template>
    </multiselect>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

const ALL_FLOWS_OPTION = { id: null, name: 'All Flows' };

export default {
  name: 'ReportsFiltersFlows',
  data() {
    return {
      selectedOption: ALL_FLOWS_OPTION,
      isLoading: false,
    };
  },
  computed: {
    ...mapGetters({
      flows: 'getBotFlows',
    }),
    flowOptions() {
      return [ALL_FLOWS_OPTION, ...this.flows];
    },
  },
  mounted() {
    this.fetchFlows();
  },
  methods: {
    async fetchFlows() {
      this.isLoading = true;
      try {
        await this.$store.dispatch('fetchBotFlows');
      } catch (error) {
        // Error handling done in store action
      } finally {
        this.isLoading = false;
      }
    },
    handleInput() {
      this.$emit('flow-filter-selection', this.selectedOption);
    },
  },
};
</script>
