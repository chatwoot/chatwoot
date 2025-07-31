export const getters = {
  getLeaves: state => Object.values(state.records),
  getLeave: state => id => state.records[id],
  getUIFlags: state => state.uiFlags,
  getMeta: state => state.meta,

  getPendingLeaves: state => {
    return Object.values(state.records).filter(
      leave => leave.status === 'pending'
    );
  },

  getApprovedLeaves: state => {
    return Object.values(state.records).filter(
      leave => leave.status === 'approved'
    );
  },

  getRejectedLeaves: state => {
    return Object.values(state.records).filter(
      leave => leave.status === 'rejected'
    );
  },

  getLeavesByAgent: state => agentId => {
    return Object.values(state.records).filter(
      leave => leave.agent_id === agentId
    );
  },

  getLeavesByDateRange: state => (startDate, endDate) => {
    return Object.values(state.records).filter(leave => {
      const leaveStart = new Date(leave.start_date);
      const leaveEnd = new Date(leave.end_date);
      const rangeStart = new Date(startDate);
      const rangeEnd = new Date(endDate);

      return leaveStart <= rangeEnd && leaveEnd >= rangeStart;
    });
  },
};
