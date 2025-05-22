<script>
import { mapGetters } from 'vuex';

export default {
  name: 'ReportsFiltersInboxes',
  emits: ['inboxFilterSelection'],
  props: {
    type: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selectedOption: null,
    };
  },
  computed: {
    ...mapGetters({
      options: 'inboxes/getInboxes',
    }),
    inboxes() {
      return this.options.filter(e => e.channel_type == this.type);
    },
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
      :placeholder="$t('CAMPAIGN_REPORTS.INBOX_FILTER_DROPDOWN_LABEL')"
      label="name"
      track-by="id"
      :options="inboxes"
      :option-height="24"
      :show-labels="false"
      @update:model-value="handleInput"
    />
  </div>
</template>
