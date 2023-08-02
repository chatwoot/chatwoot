import { mapGetters } from 'vuex';

export default {
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      currentChat: 'getSelectedChat',
      currentAccountId: 'getCurrentAccountId',
    }),
    assignableAgents() {
      if (!this.currentChat.id) {
        return [];
      }
      const { id, inbox_id: inboxId } = this.currentChat;
      return this.$store.getters['inboxAssignableAgents/getAssignableAgents']({
        inboxIds: [inboxId],
        conversationIds: [id],
      });
    },
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
      const agentsByUpdatedPresence = this.getAgentsByUpdatedPresence(agents);
      const none = this.createNoneAgent;
      const filteredAgentsByAvailability = this.sortedAgentsByAvailability(
        agentsByUpdatedPresence
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
    getAgentsByUpdatedPresence(agents) {
      // Here we are updating the availability status of the current user dynamically (live) based on the current account availability status
      const agentsWithDynamicPresenceUpdate = agents.map(item =>
        item.id === this.currentUser.id
          ? {
              ...item,
              availability_status: this.currentUser.accounts.find(
                account => account.id === this.currentAccountId
              ).availability_status,
            }
          : item
      );
      return agentsWithDynamicPresenceUpdate;
    },
  },
};
