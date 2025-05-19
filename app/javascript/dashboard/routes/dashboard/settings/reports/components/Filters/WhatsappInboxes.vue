<script>
import { mapGetters } from 'vuex';

export default {
  name: 'ReportsFiltersWhatsappInboxes',
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
    whatsappInboxes() {
      return this.options.filter(
        e => e.channel_type == 'Channel::Whatsapp'
      );
    },
  },
  mounted() {
    this.$store.dispatch('inboxes/get');
    console.log('Options: ', this.options);
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
      :options="whatsappInboxes"
      :option-height="24"
      :show-labels="false"
      @update:model-value="handleInput"
    />
  </div>
</template>
