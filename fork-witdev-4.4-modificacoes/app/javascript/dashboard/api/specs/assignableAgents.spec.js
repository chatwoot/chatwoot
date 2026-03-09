import assignableAgentsAPI from '../assignableAgents';

describe('#AssignableAgentsAPI', () => {
  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      get: vi.fn(() => Promise.resolve()),
      patch: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#getAssignableAgents', () => {
      assignableAgentsAPI.get([1]);
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/assignable_agents', {
        params: {
          inbox_ids: [1],
        },
      });
    });
  });
});
