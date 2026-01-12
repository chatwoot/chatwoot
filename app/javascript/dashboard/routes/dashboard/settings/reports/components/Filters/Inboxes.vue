<script>
import { mapGetters } from 'vuex';

export default {
  name: 'ReportsFiltersInboxes',
  emits: ['inboxFilterSelection'],
  data() {
    return {
      selectedOptions: [],
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
      this.$emit('inboxFilterSelection', this.selectedOptions);
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
      :placeholder="$t('INBOX_REPORTS.FILTER_DROPDOWN_LABEL')"
      selected-label
      :select-label="$t('FORMS.MULTISELECT.ENTER_TO_SELECT')"
      :deselect-label="$t('FORMS.MULTISELECT.ENTER_TO_REMOVE')"
      @update:model-value="handleInput"
    />
  </div>
</template>
