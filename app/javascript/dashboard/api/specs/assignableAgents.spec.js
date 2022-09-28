import assignableAgentsAPI from '../assignableAgents';
import describeWithAPIMock from './apiSpecHelper';

describe('#AssignableAgentsAPI', () => {
  describeWithAPIMock('API calls', context => {
    it('#getAssignableAgents', () => {
      assignableAgentsAPI.get([1]);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/assignable_agents',
        {
          params: {
            inbox_ids: [1],
          },
        }
      );
    });
  });
});
