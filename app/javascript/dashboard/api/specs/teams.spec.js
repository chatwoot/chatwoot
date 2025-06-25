import teamsAPI from '../teams';
import ApiClient from '../ApiClient';
import describeWithAPIMock from './apiSpecHelper';

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
  describeWithAPIMock('API calls', context => {
    it('#getAgents', () => {
      teamsAPI.getAgents({ teamId: 1 });
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/teams/1/team_members'
      );
    });

    it('#addAgents', () => {
      teamsAPI.addAgents({ teamId: 1, agentsList: { user_ids: [1, 10, 21] } });
      expect(context.axiosMock.post).toHaveBeenCalledWith(
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
      expect(context.axiosMock.patch).toHaveBeenCalledWith(
        '/api/v1/teams/1/team_members',
        {
          user_ids: agentsList,
        }
      );
    });
  });
});
