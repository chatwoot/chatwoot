import axios from 'axios';
import { actions } from '../../reports';
import * as DownloadHelper from 'dashboard/helper/downloadHelper';

global.open = vi.fn();
global.axios = axios;

vi.mock('axios');
vi.spyOn(DownloadHelper, 'downloadCsvFile');

describe('#actions', () => {
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
      await actions.downloadAgentReports(1, param);
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
      await actions.downloadLabelReports(1, param);
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
      await actions.downloadInboxReports(1, param);
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
      await actions.downloadInboxReports(1, param);
      expect(DownloadHelper.downloadCsvFile).toBeCalledWith(
        param.fileName,
        data
      );
    });
  });
});
