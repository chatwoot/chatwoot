/* eslint no-console: 0 */
import * as types from '../mutation-types';
import Report from '../../api/reports';

const state = {
  fetchingStatus: false,
  uiFlags: {
    isFetchingAgentConversationMetric: false,
    isFetchingAgentContactMetric: false,
    isFetchingAgentPlannedMetric: false,
    isFetchingAgentCalendarItems: false,
  },
  agentConversationMetric: [],
  agentContactMetric: [],
  agentPlannedMetric: [],
  agentCalendarItems: [],
};

const getters = {
  getAgentDashboardConversationMetric(_state) {
    return _state.agentConversationMetric;
  },
  getAgentDashboardContactMetric(_state) {
    return _state.agentContactMetric;
  },
  getAgentDashboardCalendarItems(_state) {
    return _state.agentCalendarItems;
  },
  getAgentDashboardPlannedMetric(_state) {
    return _state.agentPlannedMetric;
  },
  getAgentDashboardUIFlags($state) {
    return $state.uiFlags;
  },
};

export const actions = {
  fetchAgentDashboardPlannedMetric({ commit }) {
    commit(types.default.TOGGLE_AGENT_DASHBOARD_PLANNED_METRIC_LOADING, true);
    Report.getAgentPlannedMetrics()
      .then(plannedMetric => {
        commit(
          types.default.SET_AGENT_DASHBOARD_PLANNED_METRIC,
          plannedMetric.data
        );
        commit(
          types.default.TOGGLE_AGENT_DASHBOARD_PLANNED_METRIC_LOADING,
          false
        );
      })
      .catch(() => {
        commit(
          types.default.TOGGLE_AGENT_DASHBOARD_PLANNED_METRIC_LOADING,
          false
        );
      });
  },
  fetchAgentDashboardConversationMetric({ commit }) {
    commit(
      types.default.TOGGLE_AGENT_DASHBOARD_CONVERSATION_METRIC_LOADING,
      true
    );
    Report.getAgentConversationsMetrics()
      .then(agentConversationMetric => {
        commit(
          types.default.SET_AGENT_DASHBOARD_CONVERSATION_METRIC,
          agentConversationMetric.data
        );
        commit(
          types.default.TOGGLE_AGENT_DASHBOARD_CONVERSATION_METRIC_LOADING,
          false
        );
      })
      .catch(() => {
        commit(
          types.default.TOGGLE_AGENT_DASHBOARD_CONVERSATION_METRIC_LOADING,
          false
        );
      });
  },
  fetchAgentDashboardContactMetric({ commit }) {
    commit(types.default.TOGGLE_AGENT_DASHBOARD_CONTACT_METRIC_LOADING, true);
    Report.getAgentContactsMetrics()
      .then(agentContactMetric => {
        commit(
          types.default.SET_AGENT_DASHBOARD_CONTACT_METRIC,
          agentContactMetric.data
        );
        commit(
          types.default.TOGGLE_AGENT_DASHBOARD_CONTACT_METRIC_LOADING,
          false
        );
      })
      .catch(() => {
        commit(
          types.default.TOGGLE_AGENT_DASHBOARD_CONTACT_METRIC_LOADING,
          false
        );
      });
  },
  fetchAgentDashboardPlannedConversations({ commit }) {
    commit(types.default.TOGGLE_AGENT_DASHBOARD_CALENDAR_ITEMS_LOADING, true);
    Report.getAgentPlannedConversations()
      .then(plannedConversations => {
        commit(
          types.default.SET_AGENT_DASHBOARD_CALENDAR_ITEMS,
          plannedConversations.data
        );
        commit(
          types.default.TOGGLE_AGENT_DASHBOARD_CALENDAR_ITEMS_LOADING,
          false
        );
      })
      .catch(() => {
        commit(
          types.default.TOGGLE_AGENT_DASHBOARD_CALENDAR_ITEMS_LOADING,
          false
        );
      });
  },
};

const mutations = {
  [types.default.SET_AGENT_DASHBOARD_CONVERSATION_METRIC](_state, metricData) {
    _state.agentConversationMetric = metricData;
  },
  [types.default.TOGGLE_AGENT_DASHBOARD_CONVERSATION_METRIC_LOADING](
    _state,
    flag
  ) {
    _state.uiFlags.isFetchingAgentConversationMetric = flag;
  },
  [types.default.SET_AGENT_DASHBOARD_CONTACT_METRIC](_state, metricData) {
    _state.agentContactMetric = metricData;
  },
  [types.default.TOGGLE_AGENT_DASHBOARD_CONTACT_METRIC_LOADING](_state, flag) {
    _state.uiFlags.isFetchingAgentContactMetric = flag;
  },
  [types.default.SET_AGENT_DASHBOARD_PLANNED_METRIC](_state, metricData) {
    _state.agentPlannedMetric = metricData;
  },
  [types.default.TOGGLE_AGENT_DASHBOARD_PLANNED_METRIC_LOADING](_state, flag) {
    _state.uiFlags.isFetchingAgentPlannedMetric = flag;
  },
  [types.default.SET_AGENT_DASHBOARD_CALENDAR_ITEMS](_state, data) {
    _state.agentCalendarItems = data;
  },
  [types.default.TOGGLE_AGENT_DASHBOARD_CALENDAR_ITEMS_LOADING](_state, flag) {
    _state.uiFlags.isFetchingAgentCalendarItems = flag;
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
