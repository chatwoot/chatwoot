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

    it('#getAssignableAgents with AI assignees', () => {
      assignableAgentsAPI.get([1], {
        includeAIAssignees: true,
        conversationId: 42,
      });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/assignable_agents', {
        params: {
          inbox_ids: [1],
          include_ai_assignees: true,
          conversation_id: 42,
        },
      });
    });
  });
});
