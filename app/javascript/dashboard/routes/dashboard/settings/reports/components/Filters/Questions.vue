<template>
    <div class="multiselect-wrap--small">
      <multiselect
        v-model="selectedOption"
        class="no-margin"
        :placeholder="$t('CSAT_REPORTS.FILTERS.QUESTIONS.PLACEHOLDER')"
        label="content"
        track-by="id"
        :options="options"
        :option-height="24"
        :show-labels="false"
        @input="handleInput"
        :multiple="multiple"
      />
    </div>
  </template>
  <script>
  import { mapGetters } from 'vuex';
  
  export default {
    name: 'ReportsFiltersQuestions',
    props: {
      multiple: {
        type: Boolean,
        default: false,
      }
    },
    data() {
      return {
        selectedOption: null,
      };
    },
    computed: {
      ...mapGetters({
        options: 'csat/getAllQuestions',
      }),
    },
    mounted() {
      this.$store.dispatch('csat/getAllQuestions');
    },
    methods: {
      handleInput() {
        this.$emit('question-filter-selection', this.selectedOption);
      },
    },
  };
  </script>
  