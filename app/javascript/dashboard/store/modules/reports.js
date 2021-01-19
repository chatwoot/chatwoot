/* eslint no-console: 0 */
/* eslint no-param-reassign: 0 */
/* eslint no-shadow: 0 */
import compareAsc from 'date-fns/compareAsc';
import fromUnixTime from 'date-fns/fromUnixTime';

import * as types from '../mutation-types';
import Report from '../../api/reports';

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
    Report.getAccountReports(
      reportObj.metric,
      reportObj.from,
      reportObj.to
    ).then(accountReport => {
      let { data } = accountReport;
      data = data.filter(
        el => compareAsc(new Date(), fromUnixTime(el.timestamp)) > -1
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
    Report.getAccountSummary(reportObj.from, reportObj.to)
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
        let csvContent = 'data:text/csv;charset=utf-8,' + response.data;
        var encodedUri = encodeURI(csvContent);
        window.open(encodedUri);
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
    // Average First Response Time
    let avgFirstResTimeInHr = 0;
    if (summaryData.avg_first_response_time) {
      avgFirstResTimeInHr = (
        summaryData.avg_first_response_time / 3600
      ).toFixed(2);
      avgFirstResTimeInHr = `${avgFirstResTimeInHr} Hr`;
    }
    // Average Resolution Time
    let avgResolutionTimeInHr = 0;
    if (summaryData.avg_resolution_time) {
      avgResolutionTimeInHr = (summaryData.avg_resolution_time / 3600).toFixed(
        2
      );
      avgResolutionTimeInHr = `${avgResolutionTimeInHr} Hr`;
    }
    _state.accountSummary.avg_first_response_time = avgFirstResTimeInHr;
    _state.accountSummary.avg_resolution_time = avgResolutionTimeInHr;
  },
};

export default {
  state,
  getters,
  actions,
  mutations,
};
