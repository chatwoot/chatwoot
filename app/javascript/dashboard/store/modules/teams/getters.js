export const getters = {
  getTeams($state) {
    return Object.values($state.records);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  getTeam: $state => id => {
    const team = $state.records[id];
    return team || {};
  },
  getMeta: $state => {
    return $state.meta;
  },
};
