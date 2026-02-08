import axios from 'axios';
import { actions } from '../../reports';
import * as types from '../../../mutation-types';
import { STATUS } from '../../../constants';
import * as DownloadHelper from 'dashboard/helper/downloadHelper';
import { flushPromises } from '@vue/test-utils';

global.open = vi.fn();
global.axios = axios;
global.URL.createObjectURL = vi.fn();

vi.mock('axios');
vi.spyOn(DownloadHelper, 'downloadCsvFile');

describe('#actions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('#fetchAccountSummary', () => {
    it('sends correct actions if API is success', async () => {
      const commit = vi.fn();
      const reportObj = {
        from: 1630504922510,
        to: 1630504922510,
        type: 'account',
        id: 1,
        groupBy: 'day',
        businessHours: true,
      };
      const summaryData = {
        conversations_count: 10,
        incoming_messages_count: 20,
        outgoing_messages_count: 15,
        avg_first_response_time: 30,
        avg_resolution_time: 60,
        resolutions_count: 5,
        bot_resolutions_count: 2,
        bot_handoffs_count: 1,
        reply_time: 25,
      };
      axios.get.mockResolvedValue({ data: summaryData });

      actions.fetchAccountSummary({ commit }, reportObj);
      await flushPromises();

      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACCOUNT_SUMMARY_STATUS, STATUS.FETCHING],
        [types.default.SET_ACCOUNT_SUMMARY, summaryData],
        [types.default.SET_ACCOUNT_SUMMARY_STATUS, STATUS.FINISHED],
      ]);
    });

    it('sends correct actions if API fails', async () => {
      const commit = vi.fn();
      const reportObj = {
        from: 1630504922510,
        to: 1630504922510,
      };
      axios.get.mockRejectedValue(new Error('API Error'));

      actions.fetchAccountSummary({ commit }, reportObj);
      await flushPromises();

      expect(commit.mock.calls).toEqual([
        [types.default.SET_ACCOUNT_SUMMARY_STATUS, STATUS.FETCHING],
        [types.default.SET_ACCOUNT_SUMMARY_STATUS, STATUS.FAILED],
      ]);
    });
  });

  describe('#fetchBotSummary', () => {
    it('sends correct actions if API is success', async () => {
      const commit = vi.fn();
      const reportObj = {
        from: 1630504922510,
        to: 1630504922510,
        groupBy: 'day',
        businessHours: true,
      };
      const summaryData = {
        bot_resolutions_count: 10,
        bot_handoffs_count: 5,
        previous: {
          bot_resolutions_count: 8,
          bot_handoffs_count: 4,
        },
      };
      axios.get.mockResolvedValue({ data: summaryData });

      actions.fetchBotSummary({ commit }, reportObj);
      await flushPromises();

      expect(commit.mock.calls).toEqual([
        [types.default.SET_BOT_SUMMARY_STATUS, STATUS.FETCHING],
        [types.default.SET_BOT_SUMMARY, summaryData],
        [types.default.SET_BOT_SUMMARY_STATUS, STATUS.FINISHED],
      ]);
    });

    it('sends correct actions if API fails', async () => {
      const commit = vi.fn();
      const reportObj = {
        from: 1630504922510,
        to: 1630504922510,
      };
      const error = new Error('API error');
      axios.get.mockRejectedValueOnce(error);

      actions.fetchBotSummary({ commit }, reportObj);
      await flushPromises();

      expect(commit.mock.calls).toEqual([
        [types.default.SET_BOT_SUMMARY_STATUS, STATUS.FETCHING],
        [types.default.SET_BOT_SUMMARY_STATUS, STATUS.FAILED],
      ]);
    });
  });

  describe('#downloadAgentReports', () => {
    it('open CSV download prompt if API is success', async () => {
      const data = `Agent name,Conversations count,Avg first response time (Minutes),Avg resolution time (Minutes)
      Pranav,36,114,28411`;
      axios.get.mockResolvedValue({ data });

      const param = {
        from: 1630504922510,
        to: 1630504922510,
        fileName: 'agent-report-01-09-2021.csv',
      };
      actions.downloadAgentReports(1, param);
      await flushPromises();

      expect(DownloadHelper.downloadCsvFile).toBeCalledWith(
        param.fileName,
        data
      );
    });
  });

  describe('#downloadLabelReports', () => {
    it('open CSV download prompt if API is success', async () => {
      const data = `Label Title,Conversations count,Avg first response time (Minutes),Avg resolution time (Minutes)
      website,0,0,0`;
      axios.get.mockResolvedValue({ data });
      const param = {
        from: 1632335400,
        to: 1632853800,
        type: 'label',
        fileName: 'label-report-01-09-2021.csv',
      };
      actions.downloadLabelReports(1, param);
      await flushPromises();

      expect(DownloadHelper.downloadCsvFile).toBeCalledWith(
        param.fileName,
        data
      );
    });
  });

  describe('#downloadInboxReports', () => {
    it('open CSV download prompt if API is success', async () => {
      const data = `Inbox name,Conversations count,Avg first response time (Minutes),Avg resolution time (Minutes)
      Fayaz,2,127,0
      EMa,0,0,0
      Twillio WA,0,0,0`;
      axios.get.mockResolvedValue({ data });
      const param = {
        from: 1631039400,
        to: 1635013800,
        fileName: 'inbox-report-24-10-2021.csv',
      };
      actions.downloadInboxReports(1, param);
      await flushPromises();

      expect(DownloadHelper.downloadCsvFile).toBeCalledWith(
        param.fileName,
        data
      );
    });
  });

  describe('#downloadTeamReports', () => {
    it('open CSV download prompt if API is success', async () => {
      const data = `Team name,Conversations count,Avg first response time (Minutes),Avg resolution time (Minutes)
      sales team,0,0,0
      Reporting period 2021-09-23 to 2021-09-29`;
      axios.get.mockResolvedValue({ data });
      const param = {
        from: 1631039400,
        to: 1635013800,
        fileName: 'inbox-report-24-10-2021.csv',
      };
      actions.downloadInboxReports(1, param);
      await flushPromises();

      expect(DownloadHelper.downloadCsvFile).toBeCalledWith(
        param.fileName,
        data
      );
    });
  });
});
