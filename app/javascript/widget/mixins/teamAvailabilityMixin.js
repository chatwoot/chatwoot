export default {
  computed: {
    teamAvailabilityStatus() {
      if (this.availableAgents.length) {
        return this.$t('TEAM_AVAILABILITY.ONLINE');
      }
      return this.$t('TEAM_AVAILABILITY.OFFLINE');
    },
  },
};
