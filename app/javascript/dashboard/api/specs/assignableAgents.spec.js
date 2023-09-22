import assignableAgentsAPI from '../assignableAgents';

describe('#AssignableAgentsAPI', () => {
  describe('API calls', context => {
    it('#getAssignableAgents', () => {
      assignableAgentsAPI.get([1]);
      expect(axios.get).toHaveBeenCalledWith('/api/v1/assignable_agents', {
        params: {
          inbox_ids: [1],
        },
      });
    });
  });
});
