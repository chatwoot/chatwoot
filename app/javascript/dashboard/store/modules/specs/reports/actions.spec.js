import axios from 'axios';
import { actions } from '../../reports';

global.open = jest.fn();
global.axios = axios;
jest.mock('axios');

describe('#actions', () => {
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
      const mockDownloadElement = document.createElement('a');
      jest
        .spyOn(document, 'createElement')
        .mockImplementation(() => mockDownloadElement);
      await actions.downloadAgentReports(1, param);
      expect(mockDownloadElement.href).toEqual(
        'data:text/csv;charset=utf-8,Agent%20name,Conversations%20count,Avg%20first%20response%20time%20(Minutes),Avg%20resolution%20time%20(Minutes)%0A%20%20%20%20%20%20%20%20Pranav,36,114,28411'
      );
      expect(mockDownloadElement.download).toEqual(param.fileName);
    });
  });
});
