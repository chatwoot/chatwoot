export default {
  methods: {
    getAvailableAgentsText(agents) {
      const count = agents.length;
      if (count === 1) {
        const [agent] = agents;
        return `${agent.name} ${this.$t('AGENT_AVAILABILITY.IS_AVAILABLE')}`;
      }

      if (count === 2) {
        const [first, second] = agents;
        return `${first.name} ${this.$t('AGENT_AVAILABILITY.AND')} ${
          second.name
        } ${this.$t('AGENT_AVAILABILITY.ARE_AVAILABLE')}`;
      }

      const [agent] = agents;
      const rest = agents.length - 1;
      return `${agent.name} ${this.$t(
        'AGENT_AVAILABILITY.AND'
      )} ${rest} ${this.$t('AGENT_AVAILABILITY.OTHERS_ARE_AVAILABLE')}`;
    },
  },
};
