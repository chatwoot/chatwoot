import assignableAgentsAPI from '../assignableAgents';
import describeWithAPIMock from './apiSpecHelper';

describe('#AssignableAgentsAPI', () => {
  describeWithAPIMock('API calls', context => {
    it('#getAssignableAgents', () => {
      assignableAgentsAPI.get({ inboxIds: [1], conversationIds: [1] });
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/assignable_agents',
        {
          params: {
            inbox_ids: [1],
            conversation_ids: [1],
          },
        }
      );
    });
  });
});
