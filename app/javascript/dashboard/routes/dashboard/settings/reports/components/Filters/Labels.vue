<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      :placeholder="$t('LABEL_REPORTS.FILTER_DROPDOWN_LABEL')"
      label="title"
      track-by="id"
      :options="options"
      :option-height="24"
      :show-labels="false"
      @input="handleInput"
    >
      <template slot="singleLabel" slot-scope="props">
        <div class="reports-option__wrap">
          <div
            :style="{ backgroundColor: props.option.color }"
            class="reports-option__rounded--item"
          />
          <span class="reports-option__desc">
            <span class="reports-option__title">
              {{ props.option.title }}
            </span>
          </span>
        </div>
      </template>
      <template slot="option" slot-scope="props">
        <div class="reports-option__wrap">
          <div
            :style="{ backgroundColor: props.option.color }"
            class="
                reports-option__rounded--item
                reports-option__item
                reports-option__label--swatch
              "
          />
          <span class="reports-option__desc">
            <span class="reports-option__title">
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
