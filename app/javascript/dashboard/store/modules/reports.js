/* eslint no-console: 0 */
/* eslint no-param-reassign: 0 */
/* eslint no-shadow: 0 */
import * as types from '../mutation-types';
import Report from '../../api/reports';

import { downloadCsvFile } from '../../helper/downloadCsvFile';

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
};

const getters = {
  getAccountReports(_state) {
    return _state.accountReport;
  },
  getAccountSummary(_state) {
    return _state.accountSummary;
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
      reportObj.groupBy
    ).then(accountReport => {
      let { data } = accountReport;
      data = data.filter(
        el =>
          reportObj.to - el.timestamp > 0 && el.timestamp - reportObj.from >= 0
      );
      if (
        reportObj.metric === 'avg_first_response_time' ||
        reportObj.metric === 'avg_resolution_time'
      ) {
        data = data.map(element => {
          /* eslint-disable operator-assignment */
          element.value = (element.value / 3600).toFixed(2);
          return element;
        });
      }
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
      reportObj.groupBy
    )
      .then(accountSummary => {
        commit(types.default.SET_ACCOUNT_SUMMARY, accountSummary.data);
      })
      .catch(() => {
        commit(types.default.TOGGLE_ACCOUNT_REPORT_LOADING, false);
      });
  },
  downloadAgentReports(_, reportObj) {
    return Report.getAgentReports(reportObj.from, reportObj.to)
      .then(response => {
        downloadCsvFile(reportObj.fileName, response.data);
      })
      .catch(error => {
        console.error(error);
      });
  },
  downloadLabelReports(_, reportObj) {
    return Report.getLabelReports(reportObj.from, reportObj.to)
      .then(response => {
        downloadCsvFile(reportObj.fileName, response.data);
      })
      .catch(error => {
        console.error(error);
      });
  },
  downloadInboxReports(_, reportObj) {
    return Report.getInboxReports(reportObj.from, reportObj.to)
      .then(response => {
        downloadCsvFile(reportObj.fileName, response.data);
      })
      .catch(error => {
        console.error(error);
      });
  },
  downloadTeamReports(_, reportObj) {
    return Report.getTeamReports(reportObj.from, reportObj.to)
      .then(response => {
        downloadCsvFile(reportObj.fileName, response.data);
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
};

export default {
  state,
  getters,
  actions,
  mutations,
};
