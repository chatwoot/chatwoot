import LinearAPIClient from '../../integrations/linear';
import ApiClient from '../../ApiClient';

describe('#linearAPI', () => {
  it('creates correct instance', () => {
    expect(LinearAPIClient).toBeInstanceOf(ApiClient);
    expect(LinearAPIClient).toHaveProperty('getTeams');
    expect(LinearAPIClient).toHaveProperty('getTeamEntities');
    expect(LinearAPIClient).toHaveProperty('createIssue');
    expect(LinearAPIClient).toHaveProperty('link_issue');
    expect(LinearAPIClient).toHaveProperty('getLinkedIssue');
    expect(LinearAPIClient).toHaveProperty('unlinkIssue');
    expect(LinearAPIClient).toHaveProperty('searchIssues');
  });

  describe('getTeams', () => {
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

    it('creates a valid request', () => {
      LinearAPIClient.getTeams();
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/integrations/linear/teams'
      );
    });
  });

  describe('getTeamEntities', () => {
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

    it('creates a valid request', () => {
      LinearAPIClient.getTeamEntities(1);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/integrations/linear/team_entities?team_id=1'
      );
    });
  });

  describe('createIssue', () => {
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

    it('creates a valid request', () => {
      const issueData = {
        title: 'New Issue',
        description: 'Issue description',
      };
      LinearAPIClient.createIssue(issueData);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/linear/create_issue',
        issueData
      );
    });

    it('creates a valid request with conversation_id', () => {
      const issueData = {
        title: 'New Issue',
        description: 'Issue description',
        conversation_id: 123,
      };
      LinearAPIClient.createIssue(issueData);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/linear/create_issue',
        issueData
      );
    });
  });

  describe('link_issue', () => {
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

    it('creates a valid request', () => {
      LinearAPIClient.link_issue(1, 2);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/linear/link_issue',
        {
          issue_id: 2,
          conversation_id: 1,
        }
      );
    });

    it('creates a valid request with title', () => {
      LinearAPIClient.link_issue(1, 'ENG-123', 'Sample Issue');
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/linear/link_issue',
        {
          issue_id: 'ENG-123',
          conversation_id: 1,
          title: 'Sample Issue',
        }
      );
    });
  });

  describe('getLinkedIssue', () => {
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

    it('creates a valid request', () => {
      LinearAPIClient.getLinkedIssue(1);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/integrations/linear/linked_issues?conversation_id=1'
      );
    });
  });

  describe('unlinkIssue', () => {
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

    it('creates a valid request with link_id only', () => {
      LinearAPIClient.unlinkIssue('link123');
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/linear/unlink_issue',
        {
          link_id: 'link123',
          issue_id: undefined,
          conversation_id: undefined,
        }
      );
    });

    it('creates a valid request with all parameters', () => {
      LinearAPIClient.unlinkIssue('link123', 'ENG-456', 789);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/linear/unlink_issue',
        {
          link_id: 'link123',
          issue_id: 'ENG-456',
          conversation_id: 789,
        }
      );
    });
  });

  describe('searchIssues', () => {
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

    it('creates a valid request', () => {
      LinearAPIClient.searchIssues('query');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/integrations/linear/search_issue?q=query'
      );
    });
  });
});
