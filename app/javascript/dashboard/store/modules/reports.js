/* eslint no-console: 0 */
import { clampDataBetweenTimeline } from 'shared/helpers/ReportsDataHelper';
import liveReports from '../../api/liveReports';
import customReports from '../../api/customReports';
import Report from '../../api/reports';
import AnalyticsHelper from '../../helper/AnalyticsHelper';
import { REPORTS_EVENTS } from '../../helper/AnalyticsHelper/events';
import { downloadCsvFile, generateFileName } from '../../helper/downloadHelper';
import * as types from '../mutation-types';

const state = {
  fetchingStatus: false,
  botFlows: [],
  accountReport: {
    isFetching: {
      conversations_count: false,
      incoming_messages_count: false,
      outgoing_messages_count: false,
      avg_first_response_time: false,
      avg_resolution_time: false,
      resolutions_count: false,
      bot_resolutions_count: false,
      bot_handoffs_count: false,
      reply_time: false,
    },
    data: {
      conversations_count: [],
      incoming_messages_count: [],
      outgoing_messages_count: [],
      avg_first_response_time: [],
      avg_resolution_time: [],
      resolutions_count: [],
      bot_resolutions_count: [],
      bot_handoffs_count: [],
      reply_time: [],
    },
  },
  accountSummary: {
    avg_first_response_time: 0,
    avg_resolution_time: 0,
    conversations_count: 0,
    incoming_messages_count: 0,
    outgoing_messages_count: 0,
    reply_time: 0,
    resolutions_count: 0,
    bot_resolutions_count: 0,
    bot_handoffs_count: 0,
    previous: {},
  },
  botSummary: {
    bot_resolutions_count: 0,
    bot_handoffs_count: 0,
    previous: {},
  },
  overview: {
    uiFlags: {
      isFetchingAccountConversationMetric: false,
      isFetchingBotConversationMetric: false,
      isFetchingLiveChatConversationMetric: false,
      isFetchingAccountConversationsHeatmap: false,
      isFetchingAgentConversationMetric: false,
      isFetchingTeamConversationMetric: false,
      isFetchingLiveChatOtherMetric: false,
      isFetchingBotFlows: false,
    },
    accountConversationMetric: {},
    botConversationMetric: {},
    liveChatConversationMetric: {},
    liveChatOtherMetric: {},
    accountConversationHeatmap: [],
    agentConversationMetric: [],
    teamConversationMetric: [],
  },
};

const getters = {
  getAccountReports(_state) {
    return _state.accountReport;
  },
  getAccountSummary(_state) {
    return _state.accountSummary;
  },
  getBotSummary(_state) {
    return _state.botSummary;
  },
  getAccountConversationMetric(_state) {
    return _state.overview.accountConversationMetric;
  },
  getBotConversationMetric(_state) {
    return _state.overview.botConversationMetric;
  },
  getLiveChatConversationMetric(_state) {
    return _state.overview.liveChatConversationMetric;
  },
  getLiveChatOtherMetric(_state) {
    return _state.overview.liveChatOtherMetric;
  },
  getAccountConversationHeatmapData(_state) {
    return _state.overview.accountConversationHeatmap;
  },
  getAgentConversationMetric(_state) {
    return _state.overview.agentConversationMetric;
  },
  getTeamConversationMetric(_state) {
    return _state.overview.teamConversationMetric;
  },
  getOverviewUIFlags($state) {
    return $state.overview.uiFlags;
  },
  getBotFlows(_state) {
    return _state.botFlows;
  },
};

export const actions = {
  fetchAccountReport({ commit }, reportObj) {
    const { metric } = reportObj;
    commit(types.default.TOGGLE_ACCOUNT_REPORT_LOADING, {
      metric,
      value: true,
    });
    Report.getReports(reportObj).then(accountReport => {
      let { data } = accountReport;
      data = clampDataBetweenTimeline(data, reportObj.from, reportObj.to);
      commit(types.default.SET_ACCOUNT_REPORTS, {
        metric,
        data,
      });
      commit(types.default.TOGGLE_ACCOUNT_REPORT_LOADING, {
        metric,
        value: false,
      });
    });
  },
  fetchAccountConversationHeatmap({ commit }, reportObj) {
    commit(types.default.TOGGLE_HEATMAP_LOADING, true);
    Report.getReports({ ...reportObj, groupBy: 'hour' }).then(heatmapData => {
      let { data } = heatmapData;
      data = clampDataBetweenTimeline(data, reportObj.from, reportObj.to);

      commit(types.default.SET_HEATMAP_DATA, data);
      commit(types.default.TOGGLE_HEATMAP_LOADING, false);
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
  fetchBotSummary({ commit }, reportObj) {
    Report.getBotSummary({
      from: reportObj.from,
      to: reportObj.to,
      groupBy: reportObj.groupBy,
      businessHours: reportObj.businessHours,
    })
      .then(botSummary => {
        commit(types.default.SET_BOT_SUMMARY, botSummary.data);
      })
      .catch(() => {
        commit(types.default.TOGGLE_ACCOUNT_REPORT_LOADING, false);
      });
  },
  fetchLiveConversationMetric({ commit }, params = {}) {
    commit(types.default.TOGGLE_ACCOUNT_CONVERSATION_METRIC_LOADING, true);
    liveReports
      .getConversationMetric(params)
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
  fetchBotConversationMetric({ commit }, params = {}) {
    commit(types.default.TOGGLE_BOT_CONVERSATION_METRIC_LOADING, true);
    console.log('this is being called');
    customReports
      .getCustomBotAnalyticsOverviewReports(params)
      .then(botConversationMetric => {
        commit(
          types.default.SET_BOT_CONVERSATION_METRIC,
          botConversationMetric.data.data
        );
        commit(types.default.TOGGLE_BOT_CONVERSATION_METRIC_LOADING, false);
      })
      .catch(() => {
        commit(types.default.TOGGLE_BOT_CONVERSATION_METRIC_LOADING, false);
      });
  },
  async fetchBotFlows({ commit, rootGetters }) {
    commit(types.default.TOGGLE_BOT_FLOWS_LOADING, true);
    try {
      const currentAccountId = rootGetters.getCurrentAccountId;
      const response = await customReports.getBotFlows({
        accountId: currentAccountId,
      });

      console.log('responseDataForflow', response);

      if (response.data.success && response.data.flows) {
        commit(types.default.SET_BOT_FLOWS, response.data.flows);
      } else {
        commit(types.default.SET_BOT_FLOWS, []);
      }
    } catch (error) {
      console.error('Error fetching bot flows:', error);
      commit(types.default.SET_BOT_FLOWS, []);
    } finally {
      commit(types.default.TOGGLE_BOT_FLOWS_LOADING, false);
    }
  },
  fetchLiveChatConversationMetric({ commit }, params = {}) {
    commit(types.default.TOGGLE_LIVE_CHAT_CONVERSATION_METRIC_LOADING, true);
    console.log('this is being called');
    customReports
      .getCustomLiveChatAnalyticsOverviewReports(params)
      .then(liveChatConversationMetric => {
        commit(
          types.default.SET_LIVE_CHAT_CONVERSATION_METRIC,
          liveChatConversationMetric.data.data
        );
        commit(
          types.default.TOGGLE_LIVE_CHAT_CONVERSATION_METRIC_LOADING,
          false
        );
      })
      .catch(() => {
        commit(
          types.default.TOGGLE_LIVE_CHAT_CONVERSATION_METRIC_LOADING,
          false
        );
      });
  },
  fetchLiveChatOtherMetric({ commit }, params = {}) {
    commit(types.default.TOGGLE_LIVE_CHAT_OTHER_METRIC_LOADING, true);
    console.log('this is being called');
    customReports
      .getCustomLiveChatOtherMetricsReports(params)
      .then(liveChatOtherMetric => {
        commit(
          types.default.SET_LIVE_CHAT_OTHER_METRIC,
          liveChatOtherMetric.data.data
        );
        commit(types.default.TOGGLE_LIVE_CHAT_OTHER_METRIC_LOADING, false);
      })
      .catch(() => {
        commit(types.default.TOGGLE_LIVE_CHAT_OTHER_METRIC_LOADING, false);
      });
  },
  fetchAgentConversationMetric({ commit }) {
    commit(types.default.TOGGLE_AGENT_CONVERSATION_METRIC_LOADING, true);
    liveReports
      .getGroupedConversations()
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
  fetchTeamConversationMetric({ commit }) {
    commit(types.default.TOGGLE_TEAM_CONVERSATION_METRIC_LOADING, true);
    liveReports
      .getGroupedConversations({ groupBy: 'team_id' })
      .then(agentConversationMetric => {
        commit(
          types.default.SET_TEAM_CONVERSATION_METRIC,
          agentConversationMetric.data
        );
        commit(types.default.TOGGLE_TEAM_CONVERSATION_METRIC_LOADING, false);
      })
      .catch(() => {
        commit(types.default.TOGGLE_TEAM_CONVERSATION_METRIC_LOADING, false);
      });
  },
  downloadAgentReports(_, reportObj) {
    return Report.getAgentReports(reportObj)
      .then(() => {
        AnalyticsHelper.track(REPORTS_EVENTS.DOWNLOAD_REPORT, {
          reportType: 'agent',
          businessHours: reportObj?.businessHours,
        });
      })
      .catch(error => {
        console.error(error);
      });
  },
  downloadConversationReports(_, reportObj) {
    return Report.getConversationReports(reportObj)
      .then(() => {
        // downloadCsvFile(reportObj.fileName, response.data);
        AnalyticsHelper.track(REPORTS_EVENTS.DOWNLOAD_REPORT, {
          reportType: 'conversation',
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
  downloadAccountConversationHeatmap(_, reportObj) {
    Report.getConversationTrafficCSV({ daysBefore: reportObj.daysBefore })
      .then(response => {
        downloadCsvFile(
          generateFileName({
            type: 'Conversation traffic',
            to: reportObj.to,
          }),
          response.data
        );

        AnalyticsHelper.track(REPORTS_EVENTS.DOWNLOAD_REPORT, {
          reportType: 'conversation_heatmap',
          businessHours: false,
        });
      })
      .catch(error => {
        console.error(error);
      });
  },
};

const mutations = {
  [types.default.SET_ACCOUNT_REPORTS](_state, { metric, data }) {
    _state.accountReport.data[metric] = data;
  },
  [types.default.SET_HEATMAP_DATA](_state, heatmapData) {
    _state.overview.accountConversationHeatmap = heatmapData;
  },
  [types.default.TOGGLE_ACCOUNT_REPORT_LOADING](_state, { metric, value }) {
    _state.accountReport.isFetching[metric] = value;
  },
  [types.default.TOGGLE_HEATMAP_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingAccountConversationsHeatmap = flag;
  },
  [types.default.SET_ACCOUNT_SUMMARY](_state, summaryData) {
    _state.accountSummary = summaryData;
  },
  [types.default.SET_BOT_SUMMARY](_state, summaryData) {
    _state.botSummary = summaryData;
  },
  [types.default.SET_ACCOUNT_CONVERSATION_METRIC](_state, metricData) {
    _state.overview.accountConversationMetric = metricData;
  },
  [types.default.TOGGLE_ACCOUNT_CONVERSATION_METRIC_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingAccountConversationMetric = flag;
  },
  [types.default.SET_BOT_CONVERSATION_METRIC](_state, metricData) {
    _state.overview.botConversationMetric = metricData;
  },
  [types.default.SET_LIVE_CHAT_CONVERSATION_METRIC](_state, metricData) {
    _state.overview.liveChatConversationMetric = metricData;
  },
  [types.default.SET_LIVE_CHAT_OTHER_METRIC](_state, metricData) {
    _state.overview.liveChatOtherMetric = metricData;
  },
  [types.default.TOGGLE_BOT_CONVERSATION_METRIC_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingBotConversationMetric = flag;
  },
  [types.default.TOGGLE_LIVE_CHAT_CONVERSATION_METRIC_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingLiveChatConversationMetric = flag;
  },
  [types.default.TOGGLE_LIVE_CHAT_OTHER_METRIC_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingLiveChatOtherMetric = flag;
  },
  [types.default.SET_AGENT_CONVERSATION_METRIC](_state, metricData) {
    _state.overview.agentConversationMetric = metricData;
  },
  [types.default.SET_TEAM_CONVERSATION_METRIC](_state, metricData) {
    _state.overview.teamConversationMetric = metricData;
  },
  [types.default.TOGGLE_AGENT_CONVERSATION_METRIC_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingAgentConversationMetric = flag;
  },
  [types.default.TOGGLE_TEAM_CONVERSATION_METRIC_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingTeamConversationMetric = flag;
  },
  [types.default.SET_BOT_FLOWS](_state, flows) {
    _state.botFlows = flows;
  },
  [types.default.TOGGLE_BOT_FLOWS_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingBotFlows = flag;
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
