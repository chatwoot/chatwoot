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
      const onlineAgents = this.getOnlineAgents(agents);
      const busyAgents = this.getBusyAgents(agents);
      const offlineAgents = this.getOfflineAgents(agents);
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
    getOnlineAgents(agents) {
      return agents
        .filter(agent => agent.availability_status === 'online')
        .sort((a, b) => a.name.localeCompare(b.name));
    },
    getBusyAgents(agents) {
      return agents
        .filter(agent => agent.availability_status === 'busy')
        .sort((a, b) => a.name.localeCompare(b.name));
    },
    getOfflineAgents(agents) {
      return agents
        .filter(agent => agent.availability_status === 'offline')
        .sort((a, b) => a.name.localeCompare(b.name));
    },
  },
};
