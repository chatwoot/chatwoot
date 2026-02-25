import teamsAPI from '../teams';
import ApiClient from '../ApiClient';

describe('#TeamsAPI', () => {
  it('creates correct instance', () => {
    expect(teamsAPI).toBeInstanceOf(ApiClient);
    expect(teamsAPI).toHaveProperty('get');
    expect(teamsAPI).toHaveProperty('show');
    expect(teamsAPI).toHaveProperty('create');
    expect(teamsAPI).toHaveProperty('update');
    expect(teamsAPI).toHaveProperty('delete');
    expect(teamsAPI).toHaveProperty('getAgents');
    expect(teamsAPI).toHaveProperty('addAgents');
    expect(teamsAPI).toHaveProperty('updateAgents');
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

    it('#getAgents', () => {
      teamsAPI.getAgents({ teamId: 1 });
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/teams/1/team_members'
      );
    });

    it('#addAgents', () => {
      teamsAPI.addAgents({ teamId: 1, agentsList: { user_ids: [1, 10, 21] } });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/teams/1/team_members',
        {
          user_ids: { user_ids: [1, 10, 21] },
        }
      );
    });

    it('#updateAgents', () => {
      const agentsList = { user_ids: [1, 10, 21] };
      teamsAPI.updateAgents({
        teamId: 1,
        agentsList,
      });
      expect(axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/teams/1/team_members',
        {
          user_ids: agentsList,
        }
      );
    });
  });
});
