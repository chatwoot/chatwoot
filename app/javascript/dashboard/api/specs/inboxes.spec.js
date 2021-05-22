import inboxesAPI from '../inboxes';
import ApiClient from '../ApiClient';

describe('#InboxesAPI', () => {
  it('creates correct instance', () => {
    expect(inboxesAPI).toBeInstanceOf(ApiClient);
    expect(inboxesAPI).toHaveProperty('get');
    expect(inboxesAPI).toHaveProperty('show');
    expect(inboxesAPI).toHaveProperty('create');
    expect(inboxesAPI).toHaveProperty('update');
    expect(inboxesAPI).toHaveProperty('delete');
    expect(inboxesAPI).toHaveProperty('getAssignableAgents');
    expect(inboxesAPI).toHaveProperty('getCampaigns');
  });
  describe('API calls', () => {
    let originalAxios = null;
    let axiosMock = null;
    beforeEach(() => {
      originalAxios = window.axios;
      axiosMock = {
        post: jest.fn(() => Promise.resolve()),
        get: jest.fn(() => Promise.resolve()),
      };
      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#getAssignableAgents', () => {
      inboxesAPI.getAssignableAgents(1);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/inboxes/1/assignable_agents'
      );
    });

    it('#getCampaigns', () => {
      inboxesAPI.getCampaigns(2);
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/inboxes/2/campaigns');
    });
  });
});
