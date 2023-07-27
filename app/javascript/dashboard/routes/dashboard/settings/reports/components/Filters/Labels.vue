<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      :placeholder="$t('LABEL_REPORTS.FILTER_DROPDOWN_LABEL')"
      label="title"
      track-by="id"
      :options="options"
      :option-height="24"
      :show-labels="false"
      @input="handleInput"
    >
      <template slot="singleLabel" slot-scope="props">
        <div class="flex items-center">
          <div
            :style="{ backgroundColor: props.option.color }"
            class="rounded-full h-5 w-5"
          />
          <span class="reports-option__desc">
            <span class="my-0 mx-2 text-slate-800 dark:text-slate-100">
              {{ props.option.title }}
            </span>
          </span>
        </div>
      </template>
      <template slot="option" slot-scope="props">
        <div class="flex items-center">
          <div
            :style="{ backgroundColor: props.option.color }"
            class="
                rounded-full h-5 w-5
                flex-shrink-0
                border border-solid border-slate-75 dark:border-slate-700
              "
          />
          <span class="reports-option__desc">
            <span class="my-0 mx-2 text-slate-800 dark:text-slate-100">
              {{ props.option.title }}
            </span>
          </span>
        </div>
      </template>
    </multiselect>
  </div>
</template>
<script>
import { mapGetters } from 'vuex';

export default {
  name: 'ReportsFiltersLabels',
  data() {
    return {
      selectedOption: null,
    };
  },
  computed: {
    ...mapGetters({
      options: 'labels/getLabels',
    }),
  },
  mounted() {
    this.$store.dispatch('labels/get');
  },
  methods: {
    handleInput() {
      this.$emit('labels-filter-selection', this.selectedOption);
    },
  },
};
</script>
