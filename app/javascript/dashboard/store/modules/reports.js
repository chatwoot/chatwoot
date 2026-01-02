/* eslint no-console: 0 */
import * as types from '../mutation-types';
import { STATUS } from '../constants';
import Report from '../../api/reports';
import { downloadCsvFile, generateFileName } from '../../helper/downloadHelper';
import AnalyticsHelper from '../../helper/AnalyticsHelper';
import { REPORTS_EVENTS } from '../../helper/AnalyticsHelper/events';
import { clampDataBetweenTimeline } from 'shared/helpers/ReportsDataHelper';
import liveReports from '../../api/liveReports';

const state = {
  fetchingStatus: false,
  accountSummaryFetchingStatus: STATUS.FINISHED,
  botSummaryFetchingStatus: STATUS.FINISHED,
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
      booking_links_sent: false,
      booking_forms_completed: false,
      handoff_links_sent: false,
      handoff_forms_completed: false,
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
      booking_links_sent: [],
      booking_forms_completed: [],
      handoff_links_sent: [],
      handoff_forms_completed: [],
    },
  },
  // Cache for booking stats to avoid duplicate API calls
  bookingStatsCache: {
    data: null,
    params: null,
    timestamp: null,
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
  bookingSummary: {
    booking_links_sent: 0,
    booking_forms_completed: 0,
    previous: {},
  },
  handoffSummary: {
    handoff_links_sent: 0,
    handoff_forms_completed: 0,
    previous: {},
  },
  bookingSummaryFetchingStatus: STATUS.FINISHED,
  handoffSummaryFetchingStatus: STATUS.FINISHED,
  overview: {
    uiFlags: {
      isFetchingAccountConversationMetric: false,
      isFetchingAccountConversationsHeatmap: false,
      isFetchingAccountResolutionsHeatmap: false,
      isFetchingAgentConversationMetric: false,
      isFetchingTeamConversationMetric: false,
    },
    accountConversationMetric: {},
    accountConversationHeatmap: [],
    accountResolutionHeatmap: [],
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
  getAccountSummaryFetchingStatus(_state) {
    return _state.accountSummaryFetchingStatus;
  },
  getBotSummaryFetchingStatus(_state) {
    return _state.botSummaryFetchingStatus;
  },
  getBookingSummary(_state) {
    return _state.bookingSummary;
  },
  getBookingSummaryFetchingStatus(_state) {
    return _state.bookingSummaryFetchingStatus;
  },
  getHandoffSummary(_state) {
    return _state.handoffSummary;
  },
  getHandoffSummaryFetchingStatus(_state) {
    return _state.handoffSummaryFetchingStatus;
  },
  getAccountConversationMetric(_state) {
    return _state.overview.accountConversationMetric;
  },
  getAccountConversationHeatmapData(_state) {
    return _state.overview.accountConversationHeatmap;
  },
  getAccountResolutionHeatmapData(_state) {
    return _state.overview.accountResolutionHeatmap;
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
};

export const actions = {
  fetchAccountReport({ commit, state: currentState }, reportObj) {
    const { metric } = reportObj;
    commit(types.default.TOGGLE_ACCOUNT_REPORT_LOADING, {
      metric,
      value: true,
    });
    
    // Map metric to its type and field
    const metricConfig = {
      booking_links_sent: { type: 'booking', field: 'links_sent', group: 'booking' },
      booking_forms_completed: { type: 'booking', field: 'forms_completed', group: 'booking' },
      handoff_links_sent: { type: 'handoff', field: 'links_sent', group: 'handoff' },
      handoff_forms_completed: { type: 'handoff', field: 'forms_completed', group: 'handoff' },
    };
    
    const config = metricConfig[metric];
    
    // Use booking stats endpoint for new metrics
    if (config) {
      // Check if data already exists (already fetched for any metric)
      const cacheKey = JSON.stringify({ 
        from: reportObj.from, 
        to: reportObj.to, 
        groupBy: reportObj.groupBy
      });
      const cachedKey = currentState.bookingStatsCache.params;
      const isCached = cachedKey === cacheKey && currentState.bookingStatsCache.data !== null;
      
      if (isCached) {
        // Extract the specific field for this metric from cached breakdown data
        const rawBreakdownData = currentState.bookingStatsCache.data;
        const metricData = rawBreakdownData.map(item => ({
          timestamp: item.timestamp,
          value: item[metric] || 0,
          count: 0
        }));
        
        commit(types.default.SET_ACCOUNT_REPORTS, { metric, data: metricData });
        commit(types.default.TOGGLE_ACCOUNT_REPORT_LOADING, { metric, value: false });
        return;
      }
      
      // Make single API call that returns ALL fields in breakdown
      Report.getBookingStats(reportObj).then(response => {
        const rawBreakdownData = response.data; // Contains all 4 fields per data point
        
        // Cache the full breakdown data
        commit(types.default.SET_BOOKING_STATS_CACHE, {
          data: rawBreakdownData,
          params: cacheKey,
          timestamp: Date.now(),
        });
        
        // Populate ALL 4 metrics from the single response
        Object.keys(metricConfig).forEach(metricKey => {
          const metricData = rawBreakdownData.map(item => ({
            timestamp: item.timestamp,
            value: item[metricKey] || 0,
            count: 0
          }));
          
          commit(types.default.SET_ACCOUNT_REPORTS, { metric: metricKey, data: metricData });
          commit(types.default.TOGGLE_ACCOUNT_REPORT_LOADING, { metric: metricKey, value: false });
        });
      }).catch(() => {
        // Turn off loading for all metrics
        Object.keys(metricConfig).forEach(metricKey => {
          commit(types.default.TOGGLE_ACCOUNT_REPORT_LOADING, { metric: metricKey, value: false });
        });
      });
    } else {
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
    }
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
  fetchAccountResolutionHeatmap({ commit }, reportObj) {
    commit(types.default.TOGGLE_RESOLUTION_HEATMAP_LOADING, true);
    Report.getReports({ ...reportObj, groupBy: 'hour' }).then(heatmapData => {
      let { data } = heatmapData;
      data = clampDataBetweenTimeline(data, reportObj.from, reportObj.to);

      commit(types.default.SET_RESOLUTION_HEATMAP_DATA, data);
      commit(types.default.TOGGLE_RESOLUTION_HEATMAP_LOADING, false);
    });
  },
  fetchAccountSummary({ commit }, reportObj) {
    commit(types.default.SET_ACCOUNT_SUMMARY_STATUS, STATUS.FETCHING);
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
        commit(types.default.SET_ACCOUNT_SUMMARY_STATUS, STATUS.FINISHED);
      })
      .catch(() => {
        commit(types.default.SET_ACCOUNT_SUMMARY_STATUS, STATUS.FAILED);
      });
  },
  fetchBotSummary({ commit }, reportObj) {
    commit(types.default.SET_BOT_SUMMARY_STATUS, STATUS.FETCHING);
    Report.getBotSummary({
      from: reportObj.from,
      to: reportObj.to,
      groupBy: reportObj.groupBy,
      businessHours: reportObj.businessHours,
    })
      .then(botSummary => {
        commit(types.default.SET_BOT_SUMMARY, botSummary.data);
        commit(types.default.SET_BOT_SUMMARY_STATUS, STATUS.FINISHED);
      })
      .catch(() => {
        commit(types.default.SET_BOT_SUMMARY_STATUS, STATUS.FAILED);
      });
  },
  fetchBookingSummary({ commit }, reportObj) {
    commit(types.default.SET_BOOKING_SUMMARY_STATUS, STATUS.FETCHING);
    Report.getBookingSummary({ ...reportObj, metricType: 'booking' })
      .then(bookingSummary => {
        commit(types.default.SET_BOOKING_SUMMARY, bookingSummary.data);
        commit(types.default.SET_BOOKING_SUMMARY_STATUS, STATUS.FINISHED);
      })
      .catch(() => {
        commit(types.default.SET_BOOKING_SUMMARY_STATUS, STATUS.FAILED);
      });
  },
  fetchHandoffSummary({ commit }, reportObj) {
    commit(types.default.SET_HANDOFF_SUMMARY_STATUS, STATUS.FETCHING);
    Report.getBookingSummary({ ...reportObj, metricType: 'handoff' })
      .then(handoffSummary => {
        commit(types.default.SET_HANDOFF_SUMMARY, handoffSummary.data);
        commit(types.default.SET_HANDOFF_SUMMARY_STATUS, STATUS.FINISHED);
      })
      .catch(() => {
        commit(types.default.SET_HANDOFF_SUMMARY_STATUS, STATUS.FAILED);
      });
  },
  fetchAccountConversationMetric({ commit }, params = {}) {
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
  fetchAgentConversationMetric({ commit }) {
    commit(types.default.TOGGLE_AGENT_CONVERSATION_METRIC_LOADING, true);
    liveReports
      .getGroupedConversations({ groupBy: 'assignee_id' })
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
      .then(teamMetric => {
        commit(types.default.SET_TEAM_CONVERSATION_METRIC, teamMetric.data);
        commit(types.default.TOGGLE_TEAM_CONVERSATION_METRIC_LOADING, false);
      })
      .catch(() => {
        commit(types.default.TOGGLE_TEAM_CONVERSATION_METRIC_LOADING, false);
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
  [types.default.SET_RESOLUTION_HEATMAP_DATA](_state, heatmapData) {
    _state.overview.accountResolutionHeatmap = heatmapData;
  },
  [types.default.TOGGLE_ACCOUNT_REPORT_LOADING](_state, { metric, value }) {
    _state.accountReport.isFetching[metric] = value;
  },
  [types.default.SET_BOT_SUMMARY_STATUS](_state, status) {
    _state.botSummaryFetchingStatus = status;
  },
  [types.default.SET_ACCOUNT_SUMMARY_STATUS](_state, status) {
    _state.accountSummaryFetchingStatus = status;
  },
  [types.default.TOGGLE_HEATMAP_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingAccountConversationsHeatmap = flag;
  },
  [types.default.TOGGLE_RESOLUTION_HEATMAP_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingAccountResolutionsHeatmap = flag;
  },
  [types.default.SET_ACCOUNT_SUMMARY](_state, summaryData) {
    _state.accountSummary = summaryData;
  },
  [types.default.SET_BOT_SUMMARY](_state, summaryData) {
    _state.botSummary = summaryData;
  },
  [types.default.SET_BOOKING_SUMMARY](_state, summaryData) {
    _state.bookingSummary = summaryData;
  },
  [types.default.SET_BOOKING_SUMMARY_STATUS](_state, status) {
    _state.bookingSummaryFetchingStatus = status;
  },
  [types.default.SET_HANDOFF_SUMMARY](_state, summaryData) {
    _state.handoffSummary = summaryData;
  },
  [types.default.SET_HANDOFF_SUMMARY_STATUS](_state, status) {
    _state.handoffSummaryFetchingStatus = status;
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
  [types.default.SET_TEAM_CONVERSATION_METRIC](_state, metricData) {
    _state.overview.teamConversationMetric = metricData;
  },
  [types.default.TOGGLE_TEAM_CONVERSATION_METRIC_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingTeamConversationMetric = flag;
  },
  [types.default.SET_BOOKING_STATS_CACHE](_state, { data, params, timestamp }) {
    _state.bookingStatsCache.data = data;
    _state.bookingStatsCache.params = params;
    _state.bookingStatsCache.timestamp = timestamp;
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
