import axios from 'axios';
import { actions } from '../../reports';

global.open = jest.fn();
global.axios = axios;
jest.mock('axios');

const createElementSpy = () => {
  const element = document.createElement('a');
  jest.spyOn(document, 'createElement').mockImplementation(() => element);
  return element;
};

describe('#actions', () => {
  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('#downloadAgentReports', () => {
    it('open CSV download prompt if API is success', async () => {
      axios.get.mockResolvedValue({
        data: `Agent name,Conversations count,Avg first response time (Minutes),Avg resolution time (Minutes)
        Pranav,36,114,28411`,
      });
      const param = {
        from: 1630504922510,
        to: 1630504922510,
        fileName: 'agent-report-01-09-2021.csv',
      };
      const mockAgentDownloadElement = createElementSpy();
      await actions.downloadAgentReports(1, param);
      expect(mockAgentDownloadElement.href).toEqual(
        'data:text/csv;charset=utf-8,Agent%20name,Conversations%20count,Avg%20first%20response%20time%20(Minutes),Avg%20resolution%20time%20(Minutes)%0A%20%20%20%20%20%20%20%20Pranav,36,114,28411'
      );
      expect(mockAgentDownloadElement.download).toEqual(param.fileName);
    });
  });

  describe('#downloadLabelReports', () => {
    it('open CSV download prompt if API is success', async () => {
      axios.get.mockResolvedValue({
        data: `Label Title,Conversations count,Avg first response time (Minutes),Avg resolution time (Minutes)
        website,0,0,0`,
      });
      const param = {
        from: 1632335400,
        to: 1632853800,
        type: 'label',
        fileName: 'label-report-01-09-2021.csv',
      };
      const mockLabelDownloadElement = createElementSpy();
      await actions.downloadLabelReports(1, param);
      expect(mockLabelDownloadElement.href).toEqual(
        'data:text/csv;charset=utf-8,Label%20Title,Conversations%20count,Avg%20first%20response%20time%20(Minutes),Avg%20resolution%20time%20(Minutes)%0A%20%20%20%20%20%20%20%20website,0,0,0'
      );
      expect(mockLabelDownloadElement.download).toEqual(param.fileName);
    });
  });

  describe('#downloadInboxReports', () => {
    it('open CSV download prompt if API is success', async () => {
      axios.get.mockResolvedValue({
        data: `Inbox name,Conversations count,Avg first response time (Minutes),Avg resolution time (Minutes)
        Fayaz,2,127,0
        EMa,0,0,0
        Twillio WA,0,0,0`,
      });
      const param = {
        from: 1631039400,
        to: 1635013800,
        fileName: 'inbox-report-24-10-2021.csv',
      };
      const mockInboxDownloadElement = createElementSpy();
      await actions.downloadInboxReports(1, param);
      expect(mockInboxDownloadElement.href).toEqual(
        'data:text/csv;charset=utf-8,Inbox%20name,Conversations%20count,Avg%20first%20response%20time%20(Minutes),Avg%20resolution%20time%20(Minutes)%0A%20%20%20%20%20%20%20%20Fayaz,2,127,0%0A%20%20%20%20%20%20%20%20EMa,0,0,0%0A%20%20%20%20%20%20%20%20Twillio%20WA,0,0,0'
      );
      expect(mockInboxDownloadElement.download).toEqual(param.fileName);
    });
  });

  describe('#downloadTeamReports', () => {
    it('open CSV download prompt if API is success', async () => {
      axios.get.mockResolvedValue({
        data: `Team name,Conversations count,Avg first response time (Minutes),Avg resolution time (Minutes)
        sales team,0,0,0
        Reporting period 2021-09-23 to 2021-09-29`,
      });
      const param = {
        from: 1631039400,
        to: 1635013800,
        fileName: 'inbox-report-24-10-2021.csv',
      };
      const mockInboxDownloadElement = createElementSpy();
      await actions.downloadInboxReports(1, param);
      expect(mockInboxDownloadElement.href).toEqual(
        'data:text/csv;charset=utf-8,Team%20name,Conversations%20count,Avg%20first%20response%20time%20(Minutes),Avg%20resolution%20time%20(Minutes)%0A%20%20%20%20%20%20%20%20sales%20team,0,0,0%0A%20%20%20%20%20%20%20%20Reporting%20period%202021-09-23%20to%202021-09-29'
      );
      expect(mockInboxDownloadElement.download).toEqual(param.fileName);
    });
  });
});
