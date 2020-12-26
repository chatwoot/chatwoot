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
      await actions.downloadAgentReports(1, 2);
      expect(global.open).toBeCalledWith(
        'data:text/csv;charset=utf-8,Agent%20name,Conversations%20count,Avg%20first%20response%20time%20(Minutes),Avg%20resolution%20time%20(Minutes)%0A%20%20%20%20%20%20%20%20Pranav,36,114,28411'
      );
    });
  });
});
