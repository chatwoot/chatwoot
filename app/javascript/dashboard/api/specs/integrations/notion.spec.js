import NotionAPIClient from '../../integrations/notion';
import ApiClient from '../../ApiClient';

describe('#notionAPI', () => {
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
    vi.clearAllMocks();
  });

  it('creates correct instance', () => {
    expect(NotionAPIClient).toBeInstanceOf(ApiClient);
    expect(NotionAPIClient).toHaveProperty('getIssueTracker');
    expect(NotionAPIClient).toHaveProperty('updateIssueTracker');
    expect(NotionAPIClient).toHaveProperty('validateIssueTracker');
  });

  describe('getIssueTracker', () => {
    it('creates a valid request', () => {
      NotionAPIClient.getIssueTracker();

      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/integrations/notion/issue_tracker'
      );
    });
  });

  describe('updateIssueTracker', () => {
    it('creates a valid request', () => {
      const payload = {
        data_source_id: 'data-source-id',
        title_property: 'Name',
      };

      NotionAPIClient.updateIssueTracker(payload);

      expect(axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/integrations/notion/issue_tracker',
        payload
      );
    });
  });

  describe('validateIssueTracker', () => {
    it('creates a valid request', () => {
      const payload = { data_source_id: 'data-source-id' };

      NotionAPIClient.validateIssueTracker(payload);

      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/integrations/notion/validate_issue_tracker',
        payload
      );
    });
  });
});
