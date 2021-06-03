<template>
  <label-selector
    :all-labels="accountLabels"
    :saved-labels="savedLabels"
    :selected-labels="activeLabels"
  />
</template>

<script>
import { mapGetters } from 'vuex';
import LabelSelector from 'dashboard/components/widgets/LabelSelector.vue';

export default {
  components: { LabelSelector },
  computed: {
    savedLabels() {
      return [this.accountLabels[1]];
    },

    ...mapGetters({
      labelUiFlags: 'contactLabels/getUIFlags',
      accountLabels: 'labels/getLabels',
    }),

    activeLabels() {
      return this.accountLabels.filter(({ title }) =>
        this.savedLabels.includes(title)
      );
    },
  },

  watch: {
    contactId(newContactId, prevContactId) {
      if (newContactId && newContactId !== prevContactId) {
        this.fetchLabels(newContactId);
      }
    },
  },
};
</script>

<style></style>
