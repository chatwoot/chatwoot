<template>
  <label-selector
    :all-labels="allLabels"
    :saved-labels="savedLabels"
    @add="addItem"
    @remove="removeItem"
  />
</template>

<script>
import { mapGetters } from 'vuex';
import LabelSelector from 'dashboard/components/widgets/LabelSelector.vue';

export default {
  components: { LabelSelector },
  props: {
    contactId: {
      type: [String, Number],
      required: true,
    },
  },

  computed: {
    savedLabels() {
      const result = this.$store.getters['contactLabels/getContactLabels'](
        this.contactId
      );
      return result.map(value => {
        return this.allLabels.find(label => label.title === value);
      });
    },

    ...mapGetters({
      labelUiFlags: 'contactLabels/getUIFlags',
      allLabels: 'labels/getLabels',
    }),
  },

  watch: {
    contactId(newContactId, prevContactId) {
      if (newContactId && newContactId !== prevContactId) {
        this.fetchLabels(newContactId);
      }
    },
  },

  mounted() {
    const { contactId } = this;
    this.fetchLabels(contactId);
  },

  methods: {
    async onUpdateLabels(selectedLabels) {
      try {
        await this.$store.dispatch('contactLabels/update', {
          contactId: this.contactId,
          labels: selectedLabels,
        });
      } catch (error) {
        // Ignore error
      }
    },

    addItem(value) {
      const result = this.savedLabels.map(item => item.title);
      result.push(value.title);
      this.onUpdateLabels(result);
    },

    removeItem(value) {
      const result = this.savedLabels
        .map(label => label.title)
        .filter(label => label !== value);
      this.onUpdateLabels(result);
    },

    async fetchLabels(contactId) {
      if (!contactId) {
        return;
      }
      this.$store.dispatch('contactLabels/get', contactId);
    },
  },
};
</script>

<style></style>
