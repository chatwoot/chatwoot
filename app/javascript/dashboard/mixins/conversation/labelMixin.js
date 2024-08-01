import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      allLabels: 'labels/getLabels',
      accountLabels: 'labels/getTeamLabels',
    }),
    savedLabels() {
      return this.$store.getters['conversationLabels/getConversationLabels'](
        this.conversationId
      );
    },
    activeLabels() {
      return this.allLabels.filter(({ title }) =>
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
    addLabelToTicket(value) {
      const result = this.activeLabels.map(item => item.title);
      result.push(value.title);
      this.onUpdateTicketLabels(result);
    },
    removeLabelFromTicket(value) {
      const result = this.activeLabels
        .map(label => label.title)
        .filter(label => label !== value);
      this.onUpdateTicketLabels(result);
    },
    async onUpdateLabels(selectedLabels) {
      this.$store.dispatch('conversationLabels/update', {
        conversationId: this.conversationId,
        labels: selectedLabels,
      });
    },
    async onUpdateTicketLabels(selectedLabels) {
      this.$store.dispatch('ticket/update', {
        ticketId: this.ticketId,
        labels: selectedLabels,
      });
    },
  },
};
