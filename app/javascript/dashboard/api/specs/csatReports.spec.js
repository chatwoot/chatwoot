import csatReportsAPI from '../csatReports';
import ApiClient from '../ApiClient';
import describeWithAPIMock from './apiSpecHelper';

describe('#Reports API', () => {
  it('creates correct instance', () => {
    expect(csatReportsAPI).toBeInstanceOf(ApiClient);
    expect(csatReportsAPI.apiVersion).toBe('/api/v1');
    expect(csatReportsAPI).toHaveProperty('get');
    expect(csatReportsAPI).toHaveProperty('getMetrics');
  });
  describeWithAPIMock('API calls', context => {
    it('#get', () => {
      csatReportsAPI.get({ page: 1, from: 1622485800, to: 1623695400 });
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/csat_survey_responses',
        {
          params: {
            page: 1,
            since: 1622485800,
            until: 1623695400,
            sort: '-created_at',
          },
        }
      );
    });
    it('#getMetrics', () => {
      csatReportsAPI.getMetrics({ from: 1622485800, to: 1623695400 });
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/csat_survey_responses/metrics',
        {
          params: { since: 1622485800, until: 1623695400 },
        }
      );
    });
  });
});
