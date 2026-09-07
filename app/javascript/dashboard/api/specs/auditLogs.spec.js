import auditLogs from '../auditLogs';
import ApiClient from '../ApiClient';

describe('#AuditLogsAPI', () => {
  it('creates correct instance', () => {
    expect(auditLogs).toBeInstanceOf(ApiClient);
    expect(auditLogs).toHaveProperty('get');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      get: vi.fn(() => Promise.resolve()),
    };

    beforeEach(() => {
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#get passes filters as query params', () => {
      auditLogs.get({
        page: 2,
        q: 'jane',
        types: ['Inbox'],
        since: 100,
        until: 200,
        sort: 'asc',
      });
      expect(axiosMock.get).toHaveBeenCalledWith(auditLogs.url, {
        params: {
          page: 2,
          q: 'jane',
          types: ['Inbox'],
          since: 100,
          until: 200,
          sort: 'asc',
        },
      });
    });
  });
});
