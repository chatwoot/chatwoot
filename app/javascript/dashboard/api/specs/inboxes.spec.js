import inboxesAPI from '../inboxes';
import ApiClient from '../ApiClient';
import describeWithAPIMock from './apiSpecHelper';

describe('#InboxesAPI', () => {
  it('creates correct instance', () => {
    expect(inboxesAPI).toBeInstanceOf(ApiClient);
    expect(inboxesAPI).toHaveProperty('get');
    expect(inboxesAPI).toHaveProperty('show');
    expect(inboxesAPI).toHaveProperty('create');
    expect(inboxesAPI).toHaveProperty('update');
    expect(inboxesAPI).toHaveProperty('delete');
    expect(inboxesAPI).toHaveProperty('getCampaigns');
  });
  describeWithAPIMock('API calls', context => {
    it('#getCampaigns', () => {
      inboxesAPI.getCampaigns(2);
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/inboxes/2/campaigns'
      );
    });

    it('#deleteInboxAvatar', () => {
      inboxesAPI.deleteInboxAvatar(2);
      expect(context.axiosMock.delete).toHaveBeenCalledWith(
        '/api/v1/inboxes/2/avatar'
      );
    });
  });
});
