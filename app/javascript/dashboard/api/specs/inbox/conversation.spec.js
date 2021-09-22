import conversationAPI from '../../inbox/conversation';
import ApiClient from '../../ApiClient';
import describeWithAPIMock from '../apiSpecHelper';

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
  });

  describeWithAPIMock('API calls', context => {
    it('#get conversations', () => {
      conversationAPI.get({
        inboxId: 1,
        status: 'open',
        assigneeType: 'me',
        page: 1,
        labels: [],
        teamId: 1,
      });
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/conversations',
        {
          params: {
            inbox_id: 1,
            team_id: 1,
            status: 'open',
            assignee_type: 'me',
            page: 1,
            labels: [],
          },
        }
      );
    });

    it('#search', () => {
      conversationAPI.search({
        q: 'leads',
        page: 1,
      });

      expect(context.axiosMock.get).toHaveBeenCalledWith(
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
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        `/api/v1/conversations/12/toggle_status`,
        {
          status: 'online',
          snoozed_until: null,
        }
      );
    });

    it('#assignAgent', () => {
      conversationAPI.assignAgent({ conversationId: 12, agentId: 34 });
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        `/api/v1/conversations/12/assignments?assignee_id=34`,
        {}
      );
    });

    it('#assignTeam', () => {
      conversationAPI.assignTeam({ conversationId: 12, teamId: 1 });
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        `/api/v1/conversations/12/assignments`,
        {
          team_id: 1,
        }
      );
    });

    it('#markMessageRead', () => {
      conversationAPI.markMessageRead({ id: 12 });
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        `/api/v1/conversations/12/update_last_seen`
      );
    });

    it('#toggleTyping', () => {
      conversationAPI.toggleTyping({
        conversationId: 12,
        status: 'typing_on',
      });
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        `/api/v1/conversations/12/toggle_typing_status`,
        {
          typing_status: 'typing_on',
        }
      );
    });

    it('#mute', () => {
      conversationAPI.mute(45);
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/conversations/45/mute'
      );
    });

    it('#unmute', () => {
      conversationAPI.unmute(45);
      expect(context.axiosMock.post).toHaveBeenCalledWith(
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
      expect(context.axiosMock.get).toHaveBeenCalledWith(
        '/api/v1/conversations/meta',
        {
          params: {
            inbox_id: 1,
            team_id: 1,
            status: 'open',
            assignee_type: 'me',
            labels: [],
          },
        }
      );
    });

    it('#sendEmailTranscript', () => {
      conversationAPI.sendEmailTranscript({
        conversationId: 45,
        email: 'john@acme.inc',
      });
      expect(context.axiosMock.post).toHaveBeenCalledWith(
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
      expect(context.axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/conversations/45/custom_attributes',
        {
          custom_attributes: { order_d: '1001' },
        }
      );
    });
  });
});
