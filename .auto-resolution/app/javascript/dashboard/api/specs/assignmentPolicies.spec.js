import assignmentPolicies from '../assignmentPolicies';
import ApiClient from '../ApiClient';

describe('#AssignmentPoliciesAPI', () => {
  it('creates correct instance', () => {
    expect(assignmentPolicies).toBeInstanceOf(ApiClient);
    expect(assignmentPolicies).toHaveProperty('get');
    expect(assignmentPolicies).toHaveProperty('show');
    expect(assignmentPolicies).toHaveProperty('create');
    expect(assignmentPolicies).toHaveProperty('update');
    expect(assignmentPolicies).toHaveProperty('delete');
    expect(assignmentPolicies).toHaveProperty('getInboxes');
    expect(assignmentPolicies).toHaveProperty('setInboxPolicy');
    expect(assignmentPolicies).toHaveProperty('getInboxPolicy');
    expect(assignmentPolicies).toHaveProperty('removeInboxPolicy');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      get: vi.fn(() => Promise.resolve()),
      post: vi.fn(() => Promise.resolve()),
      delete: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
      // Mock accountIdFromRoute
      Object.defineProperty(assignmentPolicies, 'accountIdFromRoute', {
        get: () => '1',
        configurable: true,
      });
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#getInboxes', () => {
      assignmentPolicies.getInboxes(123);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/accounts/1/assignment_policies/123/inboxes'
      );
    });

    it('#setInboxPolicy', () => {
      assignmentPolicies.setInboxPolicy(456, 123);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/accounts/1/inboxes/456/assignment_policy',
        {
          assignment_policy_id: 123,
        }
      );
    });

    it('#getInboxPolicy', () => {
      assignmentPolicies.getInboxPolicy(456);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/accounts/1/inboxes/456/assignment_policy'
      );
    });

    it('#removeInboxPolicy', () => {
      assignmentPolicies.removeInboxPolicy(456);
      expect(axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/accounts/1/inboxes/456/assignment_policy'
      );
    });
  });
});
