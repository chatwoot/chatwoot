export const getters = {
  getTeams($state) {
    return Object.values($state.records).sort((a, b) => a.id - b.id);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getTeam: $state => id => {
    const team = $state.records[id];
    return team || {};
  },
};
