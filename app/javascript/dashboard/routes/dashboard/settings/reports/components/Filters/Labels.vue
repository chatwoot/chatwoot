<script>
import { mapGetters } from 'vuex';

export default {
  name: 'ReportsFiltersLabels',
  emits: ['labelsFilterSelection'],
  data() {
    return {
      selectedOptions: [],
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
      this.$emit('labelsFilterSelection', this.selectedOptions);
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
      label="title"
      multiple
      :close-on-select="false"
      :clear-on-select="false"
      hide-selected
      :option-height="24"
      :show-labels="false"
      :placeholder="$t('LABEL_REPORTS.FILTER_DROPDOWN_LABEL')"
      selected-label
      :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
      :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
      @update:model-value="handleInput"
    >
      <template #singleLabel="props">
        <div class="flex items-center min-w-0 gap-2">
          <div
            :style="{ backgroundColor: props.option.color }"
            class="w-5 h-5 rounded-full"
          />
          <span class="my-0 text-n-slate-12">
            {{ props.option.title }}
          </span>
        </div>
      </template>
      <template #option="props">
        <div class="flex items-center gap-2">
          <div
            :style="{ backgroundColor: props.option.color }"
            class="flex-shrink-0 w-5 h-5 border border-solid rounded-full border-n-weak"
          />

          <span class="my-0 text-n-slate-12 truncate min-w-0">
            {{ props.option.title }}
          </span>
        </div>
      </template>
    </multiselect>
  </div>
</template>
