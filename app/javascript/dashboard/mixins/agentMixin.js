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
      currentAccountId: 'getCurrentAccountId',
    }),
    isAgentSelected() {
      return this.currentChat?.meta?.assignee;
    },
    createNoneAgent() {
      return {
        confirmed: true,
        name: 'None',
        id: 0,
        role: 'agent',
        account_id: 0,
        email: 'None',
      };
    },
    agentsList() {
      const agents = this.assignableAgents || [];
      const none = this.createNoneAgent;
      const filteredAgentsByAvailability = this.sortedAgentsByAvailability(
        agents
      ).map(item =>
        item.id === this.currentUser.id
          ? {
              ...item,
              availability_status: this.currentUser.accounts.find(
                account => account.id === this.currentAccountId
              ).availability_status,
            }
          : item
      );
      const filteredAgents = [
        ...(this.isAgentSelected ? [none] : []),
        ...filteredAgentsByAvailability,
      ];
      return filteredAgents;
    },
  },
  methods: {
    getAgentsByAvailability(agents, availability) {
      return agents
        .filter(agent => agent.availability_status === availability)
        .sort((a, b) => a.name.localeCompare(b.name));
    },
    sortedAgentsByAvailability(agents) {
      const onlineAgents = this.getAgentsByAvailability(agents, 'online');
      const busyAgents = this.getAgentsByAvailability(agents, 'busy');
      const offlineAgents = this.getAgentsByAvailability(agents, 'offline');
      const filteredAgents = [...onlineAgents, ...busyAgents, ...offlineAgents];
      return filteredAgents;
    },
  },
};
