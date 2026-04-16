import summaryReportsAPI from '../summaryReports';
import ApiClient from '../ApiClient';

describe('#Summary Reports API', () => {
  const timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  it('creates correct instance', () => {
    expect(summaryReportsAPI).toBeInstanceOf(ApiClient);
    expect(summaryReportsAPI.apiVersion).toBe('/api/v2');
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

    it('includes timezone data in summary report requests', () => {
      summaryReportsAPI.getAgentReports({
        since: 1621103400,
        until: 1621621800,
        businessHours: true,
      });

      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v2/summary_reports/agent',
        {
          params: {
            since: 1621103400,
            until: 1621621800,
            business_hours: true,
            timezone,
            timezone_offset: -0,
          },
        }
      );
    });
  });
});
