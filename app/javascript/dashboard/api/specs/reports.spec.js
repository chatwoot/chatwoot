import reportsAPI from '../reports';
import ApiClient from '../ApiClient';
import describeWithAPIMock from './apiSpecHelper';

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
  });
  describeWithAPIMock('API calls', context => {
    it('#getAccountReports', () => {
      reportsAPI.getReports('conversations_count', 1621103400, 1621621800);
      expect(context.axiosMock.get).toHaveBeenCalledWith('/api/v2/reports', {
        params: {
          metric: 'conversations_count',
          since: 1621103400,
          until: 1621621800,
          type: 'account',
        },
      });
    });

    it('#getAccountSummary', () => {
      reportsAPI.getSummary(1621103400, 1621621800);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/reports/summary',
        {
          params: {
            since: 1621103400,
            until: 1621621800,
            type: 'account',
          },
        }
      );
    });

    it('#getAgentReports', () => {
      reportsAPI.getAgentReports(1621103400, 1621621800);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/reports/agents',
        {
          params: {
            since: 1621103400,
            until: 1621621800,
          },
        }
      );
    });

    it('#getLabelReports', () => {
      reportsAPI.getLabelReports(1621103400, 1621621800);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/reports/labels',
        {
          params: {
            since: 1621103400,
            until: 1621621800,
          },
        }
      );
    });

    it('#getInboxReports', () => {
      reportsAPI.getInboxReports(1621103400, 1621621800);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/reports/inboxes',
        {
          params: {
            since: 1621103400,
            until: 1621621800,
          },
        }
      );
    });
  });
});
