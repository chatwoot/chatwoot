/* eslint no-console: 0 */
import * as types from '../mutation-types';
import Report from '../../api/reports';
import { downloadCsvFile } from '../../helper/downloadHelper';
import AnalyticsHelper from '../../helper/AnalyticsHelper';
import { REPORTS_EVENTS } from '../../helper/AnalyticsHelper/events';

const state = {
  fetchingStatus: false,
  reportData: [],
  accountReport: {
    isFetching: false,
    data: [],
  },
  accountSummary: {
    avg_first_response_time: 0,
    avg_resolution_time: 0,
    conversations_count: 0,
    incoming_messages_count: 0,
    outgoing_messages_count: 0,
    resolutions_count: 0,
    previous: {},
  },
  overview: {
    uiFlags: {
      isFetchingAccountConversationMetric: false,
      isFetchingAgentConversationMetric: false,
    },
    accountConversationMetric: {},
    agentConversationMetric: [],
  },
};

const getters = {
  getAccountReports(_state) {
    return _state.accountReport;
  },
  getAccountSummary(_state) {
    return _state.accountSummary;
  },
  getAccountConversationMetric(_state) {
    return _state.overview.accountConversationMetric;
  },
  getAgentConversationMetric(_state) {
    return _state.overview.agentConversationMetric;
  },
  getOverviewUIFlags($state) {
    return $state.overview.uiFlags;
  },
};

export const actions = {
  fetchAccountReport({ commit }, reportObj) {
    commit(types.default.TOGGLE_ACCOUNT_REPORT_LOADING, true);
    Report.getReports(
      reportObj.metric,
      reportObj.from,
      reportObj.to,
      reportObj.type,
      reportObj.id,
      reportObj.groupBy,
      reportObj.businessHours
    ).then(accountReport => {
      let { data } = accountReport;
      data = data.filter(
        el =>
          reportObj.to - el.timestamp > 0 && el.timestamp - reportObj.from >= 0
      );
      commit(types.default.SET_ACCOUNT_REPORTS, data);
      commit(types.default.TOGGLE_ACCOUNT_REPORT_LOADING, false);
    });
  },
  fetchAccountSummary({ commit }, reportObj) {
    Report.getSummary(
      reportObj.from,
      reportObj.to,
      reportObj.type,
      reportObj.id,
      reportObj.groupBy,
      reportObj.businessHours
    )
      .then(accountSummary => {
        commit(types.default.SET_ACCOUNT_SUMMARY, accountSummary.data);
      })
      .catch(() => {
        commit(types.default.TOGGLE_ACCOUNT_REPORT_LOADING, false);
      });
  },
  fetchAccountConversationMetric({ commit }, reportObj) {
    commit(types.default.TOGGLE_ACCOUNT_CONVERSATION_METRIC_LOADING, true);
    Report.getConversationMetric(reportObj.type)
      .then(accountConversationMetric => {
        commit(
          types.default.SET_ACCOUNT_CONVERSATION_METRIC,
          accountConversationMetric.data
        );
        commit(types.default.TOGGLE_ACCOUNT_CONVERSATION_METRIC_LOADING, false);
      })
      .catch(() => {
        commit(types.default.TOGGLE_ACCOUNT_CONVERSATION_METRIC_LOADING, false);
      });
  },
  fetchAgentConversationMetric({ commit }, reportObj) {
    commit(types.default.TOGGLE_AGENT_CONVERSATION_METRIC_LOADING, true);
    Report.getConversationMetric(reportObj.type, reportObj.page)
      .then(agentConversationMetric => {
        commit(
          types.default.SET_AGENT_CONVERSATION_METRIC,
          agentConversationMetric.data
        );
        commit(types.default.TOGGLE_AGENT_CONVERSATION_METRIC_LOADING, false);
      })
      .catch(() => {
        commit(types.default.TOGGLE_AGENT_CONVERSATION_METRIC_LOADING, false);
      });
  },
  downloadAgentReports(_, reportObj) {
    return Report.getAgentReports(reportObj)
      .then(response => {
        downloadCsvFile(reportObj.fileName, response.data);
        AnalyticsHelper.track(REPORTS_EVENTS.DOWNLOAD_REPORT, {
          reportType: 'agent',
          businessHours: reportObj?.businessHours,
        });
      })
      .catch(error => {
        console.error(error);
      });
  },
  downloadLabelReports(_, reportObj) {
    return Report.getLabelReports(reportObj)
      .then(response => {
        downloadCsvFile(reportObj.fileName, response.data);
        AnalyticsHelper.track(REPORTS_EVENTS.DOWNLOAD_REPORT, {
          reportType: 'label',
          businessHours: reportObj?.businessHours,
        });
      })
      .catch(error => {
        console.error(error);
      });
  },
  downloadInboxReports(_, reportObj) {
    return Report.getInboxReports(reportObj)
      .then(response => {
        downloadCsvFile(reportObj.fileName, response.data);
        AnalyticsHelper.track(REPORTS_EVENTS.DOWNLOAD_REPORT, {
          reportType: 'inbox',
          businessHours: reportObj?.businessHours,
        });
      })
      .catch(error => {
        console.error(error);
      });
  },
  downloadTeamReports(_, reportObj) {
    return Report.getTeamReports(reportObj)
      .then(response => {
        downloadCsvFile(reportObj.fileName, response.data);
        AnalyticsHelper.track(REPORTS_EVENTS.DOWNLOAD_REPORT, {
          reportType: 'team',
          businessHours: reportObj?.businessHours,
        });
      })
      .catch(error => {
        console.error(error);
      });
  },
};

const mutations = {
  [types.default.SET_ACCOUNT_REPORTS](_state, accountReport) {
    _state.accountReport.data = accountReport;
  },
  [types.default.TOGGLE_ACCOUNT_REPORT_LOADING](_state, flag) {
    _state.accountReport.isFetching = flag;
  },
  [types.default.SET_ACCOUNT_SUMMARY](_state, summaryData) {
    _state.accountSummary = summaryData;
  },
  [types.default.SET_ACCOUNT_CONVERSATION_METRIC](_state, metricData) {
    _state.overview.accountConversationMetric = metricData;
  },
  [types.default.TOGGLE_ACCOUNT_CONVERSATION_METRIC_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingAccountConversationMetric = flag;
  },
  [types.default.SET_AGENT_CONVERSATION_METRIC](_state, metricData) {
    _state.overview.agentConversationMetric = metricData;
  },
  [types.default.TOGGLE_AGENT_CONVERSATION_METRIC_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingAgentConversationMetric = flag;
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
