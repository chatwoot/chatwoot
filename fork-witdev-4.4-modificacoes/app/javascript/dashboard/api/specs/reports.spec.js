import reportsAPI from '../reports';
import ApiClient from '../ApiClient';

describe('#Reports API', () => {
  it('creates correct instance', () => {
    expect(reportsAPI).toBeInstanceOf(ApiClient);
    expect(reportsAPI.apiVersion).toBe('/api/v2');
    expect(reportsAPI).toHaveProperty('get');
    expect(reportsAPI).toHaveProperty('show');
    expect(reportsAPI).toHaveProperty('create');
    expect(reportsAPI).toHaveProperty('update');
    expect(reportsAPI).toHaveProperty('delete');
    expect(reportsAPI).toHaveProperty('getReports');
    expect(reportsAPI).toHaveProperty('getSummary');
    expect(reportsAPI).toHaveProperty('getAgentReports');
    expect(reportsAPI).toHaveProperty('getLabelReports');
    expect(reportsAPI).toHaveProperty('getInboxReports');
    expect(reportsAPI).toHaveProperty('getTeamReports');
  });
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

    it('#getAccountReports', () => {
      reportsAPI.getReports({
        metric: 'conversations_count',
        from: 1621103400,
        to: 1621621800,
      });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v2/reports', {
        params: {
          metric: 'conversations_count',
          since: 1621103400,
          until: 1621621800,
          type: 'account',
          timezone_offset: -0,
        },
      });
    });

    it('#getAccountSummary', () => {
      reportsAPI.getSummary(1621103400, 1621621800);
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v2/reports/summary', {
        params: {
          business_hours: undefined,
          group_by: undefined,
          id: undefined,
          since: 1621103400,
          timezone_offset: -0,
          type: 'account',
          until: 1621621800,
        },
      });
    });

    it('#getAgentReports', () => {
      reportsAPI.getAgentReports({
        from: 1621103400,
        to: 1621621800,
        businessHours: true,
      });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v2/reports/agents', {
        params: {
          since: 1621103400,
          until: 1621621800,
          business_hours: true,
        },
      });
    });

    it('#getLabelReports', () => {
      reportsAPI.getLabelReports({ from: 1621103400, to: 1621621800 });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v2/reports/labels', {
        params: {
          since: 1621103400,
          until: 1621621800,
        },
      });
    });

    it('#getInboxReports', () => {
      reportsAPI.getInboxReports({ from: 1621103400, to: 1621621800 });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v2/reports/inboxes', {
        params: {
          since: 1621103400,
          until: 1621621800,
        },
      });
    });

    it('#getTeamReports', () => {
      reportsAPI.getTeamReports({ from: 1621103400, to: 1621621800 });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v2/reports/teams', {
        params: {
          since: 1621103400,
          until: 1621621800,
        },
      });
    });

    it('#getBotMetrics', () => {
      reportsAPI.getBotMetrics({ from: 1621103400, to: 1621621800 });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/reports/bot_metrics',
        {
          params: {
            since: 1621103400,
            until: 1621621800,
          },
        }
      );
    });

    it('#getBotSummary', () => {
      reportsAPI.getBotSummary({
        from: 1621103400,
        to: 1621621800,
        groupBy: 'date',
        businessHours: true,
      });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/reports/bot_summary',
        {
          params: {
            since: 1621103400,
            until: 1621621800,
            type: 'account',
            group_by: 'date',
            business_hours: true,
          },
        }
      );
    });

    it('#getConversationMetric', () => {
      reportsAPI.getConversationMetric('account');
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/reports/conversations',
        {
          params: {
            type: 'account',
            page: 1,
          },
        }
      );
    });
  });
});
