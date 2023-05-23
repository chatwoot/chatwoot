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
      const onlineAgents = this.getAgentsByAvailability(agents, 'online');
      const busyAgents = this.getAgentsByAvailability(agents, 'busy');
      const offlineAgents = this.getAgentsByAvailability(agents, 'offline');
      const none = this.createNoneAgent;
      const filteredAgents = [
        ...(this.isAgentSelected ? [none] : []),
        ...onlineAgents,
        ...busyAgents,
        ...offlineAgents,
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
  },
};
