import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({ accountLabels: 'labels/getLabels' }),
    savedLabels() {
      return this.$store.getters['conversationLabels/getConversationLabels'](
        this.conversationId
      );
    },
    activeLabels() {
      return this.accountLabels.filter(({ title }) =>
        this.savedLabels.includes(title)
      );
    },
    inactiveLabels() {
      return this.accountLabels.filter(
        ({ title }) => !this.savedLabels.includes(title)
      );
    },
  },
  methods: {
    addLabelToConversation(value) {
      const result = this.activeLabels.map(item => item.title);
      result.push(value.title);
      this.onUpdateLabels(result);
    },
    removeLabelFromConversation(value) {
      const result = this.activeLabels
        .map(label => label.title)
        .filter(label => label !== value);
      this.onUpdateLabels(result);
    },
    async onUpdateLabels(selectedLabels) {
      this.$store.dispatch('conversationLabels/update', {
        conversationId: this.conversationId,
        labels: selectedLabels,
      });
    },
  },
};
