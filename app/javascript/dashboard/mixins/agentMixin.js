import { mapGetters } from 'vuex';

export default {
  computed: {
    assignableAgents() {
      return this.$store.getters['inboxAssignableAgents/getAssignableAgents'](
        this.inboxId
      );
    },
    ...mapGetters({
      currentUser: 'getCurrentUser',
    }),
    agentsList() {
      const agents = this.assignableAgents || [];
      return [
        {
          confirmed: true,
          name: 'None',
          id: 0,
          role: 'agent',
          account_id: 0,
          email: 'None',
        },
        ...agents,
      ].map(item =>
        item.id === this.currentUser.id
          ? {
              ...item,
              availability_status: this.currentUser.availability_status,
            }
          : item
      );
    },
  },
};
