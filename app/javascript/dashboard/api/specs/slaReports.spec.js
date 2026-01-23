import SLAReportsAPI from '../slaReports';
import ApiClient from '../ApiClient';

describe('#SLAReports API', () => {
  it('creates correct instance', () => {
    expect(SLAReportsAPI).toBeInstanceOf(ApiClient);
    expect(SLAReportsAPI.apiVersion).toBe('/api/v1');
    expect(SLAReportsAPI).toHaveProperty('get');
    expect(SLAReportsAPI).toHaveProperty('getMetrics');
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

    it('#get', () => {
      SLAReportsAPI.get({
        page: 1,
        from: 1622485800,
        to: 1623695400,
        assigned_agent_id: 1,
        inbox_id: 1,
        team_id: 1,
        sla_policy_id: 1,
        label_list: ['label1'],
      });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/applied_slas', {
        params: {
          page: 1,
          since: 1622485800,
          until: 1623695400,
          assigned_agent_id: 1,
          inbox_id: 1,
          team_id: 1,
          sla_policy_id: 1,
          label_list: ['label1'],
        },
      });
    });
    it('#getMetrics', () => {
      SLAReportsAPI.getMetrics({
        from: 1622485800,
        to: 1623695400,
        assigned_agent_id: 1,
        inbox_id: 1,
        team_id: 1,
        sla_policy_id: 1,
        label_list: ['label1'],
      });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/applied_slas/metrics',
        {
          params: {
            since: 1622485800,
            until: 1623695400,
            assigned_agent_id: 1,
            inbox_id: 1,
            team_id: 1,
            sla_policy_id: 1,
            label_list: ['label1'],
          },
        }
      );
    });
    describe('#download', () => {
      it('downloads CSV by default', () => {
        SLAReportsAPI.download({
          from: 1622485800,
          to: 1623695400,
          assigned_agent_id: 1,
          inbox_id: 1,
          team_id: 1,
          sla_policy_id: 1,
          label_list: ['label1'],
        });

        expect(axiosMock.get).toHaveBeenCalledWith(
          '/api/v1/applied_slas/download.csv',
          {
            params: {
              since: 1622485800,
              until: 1623695400,
              assigned_agent_id: 1,
              inbox_id: 1,
              team_id: 1,
              sla_policy_id: 1,
              label_list: ['label1'],
            },
            responseType: undefined,
          }
        );
      });

      it('downloads XLSX when format is xlsx', () => {
        SLAReportsAPI.download({
          from: 1622485800,
          to: 1623695400,
          assigned_agent_id: 1,
          inbox_id: 1,
          team_id: 1,
          sla_policy_id: 1,
          label_list: ['label1'],
          format: 'xlsx',
        });

        expect(axiosMock.get).toHaveBeenCalledWith(
          '/api/v1/applied_slas/download.xlsx',
          {
            params: {
              since: 1622485800,
              until: 1623695400,
              assigned_agent_id: 1,
              inbox_id: 1,
              team_id: 1,
              sla_policy_id: 1,
              label_list: ['label1'],
            },
            responseType: 'blob',
          }
        );
      });
    });
  });
});
