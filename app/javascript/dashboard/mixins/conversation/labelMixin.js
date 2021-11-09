import { mapGetters } from 'vuex';

export default {
  computed: {
    savedLabels() {
      return this.$store.getters['conversationLabels/getConversationLabels'](
        this.conversationId
      );
    },
    ...mapGetters({ accountLabels: 'labels/getLabels' }),
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
};
