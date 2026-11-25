import reportsAPI from '../reports';
import ApiClient from '../ApiClient';

const timezoneOffset = () => -new Date().getTimezoneOffset() / 60;

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
    expect(reportsAPI).toHaveProperty('getDrilldown');
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
          business_hours: undefined,
          group_by: undefined,
          id: undefined,
          metric: 'conversations_count',
          since: 1621103400,
          until: 1621621800,
          type: 'account',
          timezone_offset: timezoneOffset(),
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
          timezone_offset: timezoneOffset(),
          type: 'account',
          until: 1621621800,
        },
      });
    });

    it('#getDrilldown', () => {
      reportsAPI.getDrilldown({
        metric: 'incoming_messages_count',
        bucketTimestamp: 1621103400,
        from: 1621103400,
        to: 1621621800,
        type: 'inbox',
        id: 1,
        groupBy: 'day',
        businessHours: false,
        page: 2,
        perPage: 25,
      });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v2/reports/drilldown', {
        params: {
          metric: 'incoming_messages_count',
          bucket_timestamp: 1621103400,
          since: 1621103400,
          until: 1621621800,
          type: 'inbox',
          id: 1,
          group_by: 'day',
          business_hours: false,
          timezone_offset: timezoneOffset(),
          page: 2,
          per_page: 25,
        },
      });
    });

    it('#getDrilldown with abort signal', () => {
      const controller = new AbortController();

      reportsAPI.getDrilldown({
        metric: 'incoming_messages_count',
        bucketTimestamp: 1621103400,
        signal: controller.signal,
      });

      expect(axiosMock.get).toHaveBeenCalledWith('/api/v2/reports/drilldown', {
        params: {
          metric: 'incoming_messages_count',
          bucket_timestamp: 1621103400,
          since: undefined,
          until: undefined,
          type: 'account',
          id: undefined,
          group_by: undefined,
          business_hours: undefined,
          timezone_offset: timezoneOffset(),
          page: undefined,
          per_page: undefined,
        },
        signal: controller.signal,
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
