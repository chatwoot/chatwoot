import reports from '../reports';
import ApiClient from '../ApiClient';

describe('#Reports API', () => {
  it('creates correct instance', () => {
    expect(reports).toBeInstanceOf(ApiClient);
    expect(reports.apiVersion).toBe('/api/v2');
    expect(reports).toHaveProperty('get');
    expect(reports).toHaveProperty('show');
    expect(reports).toHaveProperty('create');
    expect(reports).toHaveProperty('update');
    expect(reports).toHaveProperty('delete');
    expect(reports).toHaveProperty('getAccountReports');
    expect(reports).toHaveProperty('getAccountSummary');
    expect(reports).toHaveProperty('getAgentReports');
  });
});
