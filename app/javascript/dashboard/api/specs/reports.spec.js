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
    expect(reportsAPI).toHaveProperty('getAccountReports');
    expect(reportsAPI).toHaveProperty('getAccountSummary');
    expect(reportsAPI).toHaveProperty('getAgentReports');
  });
  describeWithAPIMock('API calls', context => {
    it('#getAccountReports', () => {
      reportsAPI.getAccountReports(
        'conversations_count',
        1621103400,
        1621621800
      );
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/reports/account',
        {
          params: {
            metric: 'conversations_count',
            since: 1621103400,
            until: 1621621800,
          },
        }
      );
    });

    it('#getAccountSummary', () => {
      reportsAPI.getAccountSummary(1621103400, 1621621800);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/reports/account_summary',
        {
          params: {
            since: 1621103400,
            until: 1621621800,
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
  });
});
