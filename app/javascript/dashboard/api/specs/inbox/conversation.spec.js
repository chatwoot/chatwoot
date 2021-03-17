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
  });

  describe('API calls', () => {
    let originalAxios = null;
    let axiosMock = null;

    beforeEach(() => {
      originalAxios = window.axios;
      axiosMock = { post: jest.fn(() => Promise.resolve()) };

      window.axios = axiosMock;
    });

    afterEach(() => {
      window.axios = originalAxios;
    });

    it('#unmute', () => {
      conversationAPI.unmute(45);

      expect(axiosMock.post).toHaveBeenCalledWith(
        '/api/v1/conversations/45/unmute'
      );
    });
  });
});
