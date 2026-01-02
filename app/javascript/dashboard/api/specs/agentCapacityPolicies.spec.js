import agentCapacityPolicies from '../agentCapacityPolicies';
import ApiClient from '../ApiClient';

describe('#AgentCapacityPoliciesAPI', () => {
  it('creates correct instance', () => {
    expect(agentCapacityPolicies).toBeInstanceOf(ApiClient);
    expect(agentCapacityPolicies).toHaveProperty('get');
    expect(agentCapacityPolicies).toHaveProperty('show');
    expect(agentCapacityPolicies).toHaveProperty('create');
    expect(agentCapacityPolicies).toHaveProperty('update');
    expect(agentCapacityPolicies).toHaveProperty('delete');
    expect(agentCapacityPolicies).toHaveProperty('getUsers');
    expect(agentCapacityPolicies).toHaveProperty('addUser');
    expect(agentCapacityPolicies).toHaveProperty('removeUser');
    expect(agentCapacityPolicies).toHaveProperty('createInboxLimit');
    expect(agentCapacityPolicies).toHaveProperty('updateInboxLimit');
    expect(agentCapacityPolicies).toHaveProperty('deleteInboxLimit');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      get: vi.fn(() => Promise.resolve()),
      post: vi.fn(() => Promise.resolve()),
      put: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
      // Mock accountIdFromRoute
      Object.defineProperty(agentCapacityPolicies, 'accountIdFromRoute', {
        get: () => '1',
        configurable: true,
      });
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#getUsers', () => {
      agentCapacityPolicies.getUsers(123);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/accounts/1/agent_capacity_policies/123/users'
      );
    });

    it('#addUser', () => {
      const userData = { id: 456, capacity: 20 };
      agentCapacityPolicies.addUser(123, userData);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/1/agent_capacity_policies/123/users',
        {
          user_id: 456,
          capacity: 20,
        }
      );
    });

    it('#removeUser', () => {
      agentCapacityPolicies.removeUser(123, 456);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/accounts/1/agent_capacity_policies/123/users/456'
      );
    });

    it('#createInboxLimit', () => {
      const limitData = { inboxId: 1, conversationLimit: 10 };
      agentCapacityPolicies.createInboxLimit(123, limitData);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/1/agent_capacity_policies/123/inbox_limits',
        {
          inbox_id: 1,
          conversation_limit: 10,
        }
      );
    });

    it('#updateInboxLimit', () => {
      const limitData = { conversationLimit: 15 };
      agentCapacityPolicies.updateInboxLimit(123, 789, limitData);
      expect(axiosMock.put).toHaveBeenCalledWith(
        '/api/v1/accounts/1/agent_capacity_policies/123/inbox_limits/789',
        {
          conversation_limit: 15,
        }
      );
    });

    it('#deleteInboxLimit', () => {
      agentCapacityPolicies.deleteInboxLimit(123, 789);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/accounts/1/agent_capacity_policies/123/inbox_limits/789'
      );
    });
  });
});
