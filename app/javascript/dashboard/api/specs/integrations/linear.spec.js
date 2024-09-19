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

    it('creates a valid request', () => {
      LinearAPIClient.unlinkIssue(1);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/linear/unlink_issue',
        {
          link_id: 1,
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
