export const mutations = {
  setUIFlag(state, data) {
    state.uiFlags = {
      ...state.uiFlags,
      ...data,
    };
  },

  setMeta(state, meta) {
    state.meta = meta;
  },

  setLeaves(state, leaves) {
    state.records = {};
    leaves.forEach(leave => {
      state.records[leave.id] = leave;
    });
  },

  setLeave(state, leave) {
    state.records = {
      ...state.records,
      [leave.id]: leave,
    };
  },

  deleteLeave(state, id) {
    const { [id]: deleted, ...rest } = state.records;
    state.records = rest;
  },
};
