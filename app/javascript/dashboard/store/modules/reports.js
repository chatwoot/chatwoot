/* eslint no-console: 0 */
import * as types from '../mutation-types';
import Report from '../../api/reports';
import { downloadCsvFile, generateFileName } from '../../helper/downloadHelper';
import AnalyticsHelper from '../../helper/AnalyticsHelper';
import { REPORTS_EVENTS } from '../../helper/AnalyticsHelper/events';
import {
  reconcileHeatmapData,
  clampDataBetweenTimeline,
} from 'shared/helpers/ReportsDataHelper';

const state = {
  fetchingStatus: false,
  isAccountSummaryAvailable: false,
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
  templateReport: {
    isFetching: {
      messages_sent: false,
      messages_delivered: false,
      messages_read: false,
    },
    data: {
      amount_spent: 0,
      cost_per_message_delivered: 0,
      cost_per_website_button_click: 0,
      messages_sent: [],
      messages_delivered: [],
      messages_read: [],
    },

    error: null,
    isInsightsEnabled: true,
  },

  templateSummary: {
    messages_sent: 0,
    messages_delivered: 0,
    messages_read: 0,
    cost_per_website_button_click: 0,
    cost_per_message_delivered: 0,
    amount_spent: 0,
    previous: {},
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
      isFetchingAccountConversationsHeatmap: false,
      isFetchingAgentConversationMetric: false,
    },
    accountConversationMetric: {},
    accountConversationHeatmap: [],
    agentConversationMetric: [],
  },
};

const getters = {
  getAccountReports(_state) {
    return _state.accountReport;
  },
  getTemplateReports(_state) {
    return _state.templateReport;
  },
  getAccountSummary(_state) {
    return _state.accountSummary;
  },
  getIsAccountSummaryAvailable(_state) {
    return _state.isAccountSummaryAvailable;
  },
  getTemplateSummary(_state) {
    return _state.templateSummary;
  },
  getBotSummary(_state) {
    return _state.botSummary;
  },
  getAccountConversationMetric(_state) {
    return _state.overview.accountConversationMetric;
  },
  getAccountConversationHeatmapData(_state) {
    return _state.overview.accountConversationHeatmap;
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

  fetchTemplateReport({ commit }, reportObj) {
    const { metric } = reportObj;
    commit(types.default.TOGGLE_TEMPLATE_REPORT_LOADING, {
      metric,
      value: true,
    });

    Report.getTemplateReports({
      metric: metric,
      from: reportObj.from,
      to: reportObj.to,
      businessHours: reportObj.businessHours,
      id: reportObj.id,
      channelId: reportObj.channelId,
      groupBy: reportObj.groupBy,
    })
      .then(templateReport => {
        let { data } = templateReport;
        // data = clampDataBetweenTimeline(data, reportObj.from, reportObj.to);
        commit(types.default.SET_TEMPLATE_REPORTS, {
          metric,
          data,
        });
        commit(types.default.TOGGLE_TEMPLATE_REPORT_LOADING, {
          metric,
          value: false,
        });
      })
      .catch(error => {
        commit(types.default.TOGGLE_TEMPLATE_REPORT_LOADING, {
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

      data = reconcileHeatmapData(
        data,
        state.overview.accountConversationHeatmap
      );

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

  fetchTemplateSummary({ commit }, reportObj) {
    Report.getTemplateSummary({
      from: reportObj.from,
      to: reportObj.to,
      businessHours: reportObj.businessHours,
      id: reportObj.id,
      channelId: reportObj.channelId,
      groupBy: reportObj.groupBy,
    })
      .then(templateSummary => {
        commit(types.default.SET_TEMPLATE_SUMMARY, templateSummary.data);
      })
      .catch(error => {
        const errorHtml = error.response?.data;
        if (errorHtml.includes('Insights are not enabled')) {
          commit(
            types.default.SET_TEMPLATE_ERROR,
            'Template Insights not enabled'
          );
        } else {
          commit(types.default.SET_TEMPLATE_ERROR, error.message);
        }
        commit(types.default.TOGGLE_TEMPLATE_REPORT_LOADING, false);
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

  downloadTemplateReports(_, reportObj) {
    return Report.getTemplateCsv(reportObj)
      .then(response => {
        downloadCsvFile(reportObj.fileName, response.data);
        AnalyticsHelper.track(REPORTS_EVENTS.DOWNLOAD_REPORT, {
          reportType: 'template',
          businessHours: reportObj?.businessHours,
        });
      })
      .catch(error => {
        console.error(error);
      });
  },

  downloadAccountConversationHeatmap(_, reportObj) {
    Report.getConversationTrafficCSV()
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
    _state.isAccountSummaryAvailable = true;
    _state.accountReport.data[metric] = data;
  },
  [types.default.SET_TEMPLATE_REPORTS](_state, { metric, data }) {
    _state.isAccountSummaryAvailable = false;
    _state.templateReport.error = null;
    _state.templateReport.isInsightsEnabled = true;
    _state.templateReport.data[metric] = data;
  },
  [types.default.SET_HEATMAP_DATA](_state, heatmapData) {
    _state.overview.accountConversationHeatmap = heatmapData;
  },
  [types.default.TOGGLE_ACCOUNT_REPORT_LOADING](_state, { metric, value }) {
    _state.accountReport.isFetching[metric] = value;
  },
  [types.default.TOGGLE_TEMPLATE_REPORT_LOADING](_state, { metric, value }) {
    _state.templateReport.isFetching[metric] = value;
  },
  [types.default.TOGGLE_HEATMAP_LOADING](_state, flag) {
    _state.overview.uiFlags.isFetchingAccountConversationsHeatmap = flag;
  },
  [types.default.SET_ACCOUNT_SUMMARY](_state, summaryData) {
    _state.isAccountSummaryAvailable = true;
    _state.accountSummary = summaryData;
  },
  [types.default.SET_BOT_SUMMARY](_state, summaryData) {
    _state.botSummary = summaryData;
  },
  [types.default.SET_TEMPLATE_SUMMARY](_state, summaryData) {
    _state.isAccountSummaryAvailable = false;
    _state.templateReport.error = null;
    _state.templateReport.isInsightsEnabled = true;
    _state.templateSummary = summaryData;
  },
  [types.default.SET_TEMPLATE_ERROR](_state, error) {
    if (error === 'Template Insights not enabled') {
      _state.templateReport.isInsightsEnabled = false;
    }
    _state.templateReport.error = error;
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
