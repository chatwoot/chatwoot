<script>
import { mapGetters } from 'vuex';

export default {
  name: 'ReportsFiltersInboxes',
  emits: ['inboxFilterSelection'],
  data() {
    return {
      selectedOption: null,
    };
  },
  computed: {
    ...mapGetters({
      options: 'inboxes/getInboxes',
    }),
  },
  mounted() {
    this.$store.dispatch('inboxes/get');
  },
  methods: {
    handleInput() {
      this.$emit('inboxFilterSelection', this.selectedOption);
    },
  },
};
</script>

<template>
  <div class="multiselect-wrap--small">
    <multiselect
      v-model="selectedOption"
      class="no-margin"
      :placeholder="$t('INBOX_REPORTS.FILTER_DROPDOWN_LABEL')"
      label="name"
      track-by="id"
      :options="options"
      :option-height="24"
      :show-labels="false"
      @update:model-value="handleInput"
    />
  </div>
</template>
