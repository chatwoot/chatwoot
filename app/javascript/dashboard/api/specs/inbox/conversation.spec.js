import conversationAPI from '../../inbox/conversation';
import ApiClient from '../../ApiClient';

describe('#ConversationAPI', () => {
  it('creates correct instance', () => {
    expect(conversationAPI).toBeInstanceOf(ApiClient);
    expect(conversationAPI).toHaveProperty('get');
    expect(conversationAPI).toHaveProperty('show');
    expect(conversationAPI).toHaveProperty('create');
    expect(conversationAPI).toHaveProperty('update');
    expect(conversationAPI).toHaveProperty('delete');
    expect(conversationAPI).toHaveProperty('toggleStatus');
    expect(conversationAPI).toHaveProperty('assignAgent');
    expect(conversationAPI).toHaveProperty('assignTeam');
    expect(conversationAPI).toHaveProperty('markMessageRead');
    expect(conversationAPI).toHaveProperty('toggleTyping');
    expect(conversationAPI).toHaveProperty('mute');
    expect(conversationAPI).toHaveProperty('unmute');
    expect(conversationAPI).toHaveProperty('meta');
    expect(conversationAPI).toHaveProperty('sendEmailTranscript');
    expect(conversationAPI).toHaveProperty('filter');
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

    it('#get conversations', () => {
      conversationAPI.get({
        inboxId: 1,
        status: 'open',
        assigneeType: 'me',
        page: 1,
        labels: [],
        teamId: 1,
        updatedWithin: 20,
      });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/conversations', {
        params: {
          inbox_id: 1,
          team_id: 1,
          status: 'open',
          assignee_type: 'me',
          page: 1,
          labels: [],
          updated_within: 20,
        },
      });
    });

    it('#search', () => {
      conversationAPI.search({
        q: 'leads',
        page: 1,
      });

      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/conversations/search',
        {
          params: {
            q: 'leads',
            page: 1,
          },
        }
      );
    });

    it('#toggleStatus', () => {
      conversationAPI.toggleStatus({ conversationId: 12, status: 'online' });
      expect(axiosMock.post).toHaveBeenCalledWith(
        `/api/v1/conversations/12/toggle_status`,
        {
          status: 'online',
          snoozed_until: null,
        }
      );
    });

    it('#assignAgent', () => {
      conversationAPI.assignAgent({ conversationId: 12, agentId: 34 });
      expect(axiosMock.post).toHaveBeenCalledWith(
        `/api/v1/conversations/12/assignments?assignee_id=34`,
        {}
      );
    });

    it('#assignTeam', () => {
      conversationAPI.assignTeam({ conversationId: 12, teamId: 1 });
      expect(axiosMock.post).toHaveBeenCalledWith(
        `/api/v1/conversations/12/assignments`,
        {
          team_id: 1,
        }
      );
    });

    it('#markMessageRead', () => {
      conversationAPI.markMessageRead({ id: 12 });
      expect(axiosMock.post).toHaveBeenCalledWith(
        `/api/v1/conversations/12/update_last_seen`
      );
    });

    it('#toggleTyping', () => {
      conversationAPI.toggleTyping({
        conversationId: 12,
        status: 'typing_on',
      });
      expect(axiosMock.post).toHaveBeenCalledWith(
        `/api/v1/conversations/12/toggle_typing_status`,
        {
          typing_status: 'typing_on',
        }
      );
    });

    it('#mute', () => {
      conversationAPI.mute(45);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/conversations/45/mute'
      );
    });

    it('#unmute', () => {
      conversationAPI.unmute(45);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/conversations/45/unmute'
      );
    });

    it('#meta', () => {
      conversationAPI.meta({
        inboxId: 1,
        status: 'open',
        assigneeType: 'me',
        labels: [],
        teamId: 1,
      });
      expect(axiosMock.get).toHaveBeenCalledWith('/api/v1/conversations/meta', {
        params: {
          inbox_id: 1,
          team_id: 1,
          status: 'open',
          assignee_type: 'me',
          labels: [],
        },
      });
    });

    it('#sendEmailTranscript', () => {
      conversationAPI.sendEmailTranscript({
        conversationId: 45,
        email: 'john@acme.inc',
      });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/conversations/45/transcript',
        {
          email: 'john@acme.inc',
        }
      );
    });

    it('#updateCustomAttributes', () => {
      conversationAPI.updateCustomAttributes({
        conversationId: 45,
        customAttributes: { order_d: '1001' },
      });
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/conversations/45/custom_attributes',
        {
          custom_attributes: { order_d: '1001' },
        }
      );
    });

    it('#filter', () => {
      const payload = {
        page: 1,
        queryData: {
          payload: [
            {
              attribute_key: 'status',
              filter_operator: 'equal_to',
              values: ['pending', 'resolved'],
              query_operator: 'and',
            },
            {
              attribute_key: 'assignee',
              filter_operator: 'equal_to',
              values: [3],
              query_operator: 'and',
            },
            {
              attribute_key: 'id',
              filter_operator: 'equal_to',
              values: ['This is a test'],
              query_operator: null,
            },
          ],
        },
      };
      conversationAPI.filter(payload);
      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/conversations/filter',
        payload.queryData,
        { params: { page: payload.page } }
      );
    });

    it('#getAllAttachments', () => {
      conversationAPI.getAllAttachments(1);
      expect(axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/conversations/1/attachments'
      );
    });
  });
});
