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
    expect(inboxesAPI).toHaveProperty('getCampaigns');
    expect(inboxesAPI).toHaveProperty('getAgentBot');
    expect(inboxesAPI).toHaveProperty('setAgentBot');
    expect(inboxesAPI).toHaveProperty('syncTemplates');
    expect(inboxesAPI).toHaveProperty('getMessageTemplates');
  });

  describe('API calls', () => {
    const originalAxios = window.axios;
    const axiosMock = {
      post: vi.fn(() => Promise.resolve()),
      put: vi.fn(() => Promise.resolve()),
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

    it('#getCampaigns', () => {
      inboxesAPI.getCampaigns(2);
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/inboxes/2/campaigns');
    });

    it('#deleteInboxAvatar', () => {
      inboxesAPI.deleteInboxAvatar(2);
      expect(axiosMock.delete).toHaveBeenCalledWith('/api/v1/inboxes/2/avatar');
    });

    it('#syncTemplates', () => {
      inboxesAPI.syncTemplates(2);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/inboxes/2/sync_templates'
      );
    });

    it('#getMessageTemplates', () => {
      const controller = new AbortController();

      inboxesAPI.getMessageTemplates(
        2,
        { name: 'welcome' },
        { signal: controller.signal }
      );

      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/inboxes/2/message_templates',
        {
          signal: controller.signal,
          params: { name: 'welcome' },
        }
      );
    });

    it('#updateWhatsappBusinessManagementToken', () => {
      inboxesAPI.updateWhatsappBusinessManagementToken(2, 'business-token');
      expect(axiosMock.put).toHaveBeenCalledWith(
        '/api/v1/inboxes/2/whatsapp_business_management_token',
        { business_management_token: 'business-token' }
      );
    });
  });
});
