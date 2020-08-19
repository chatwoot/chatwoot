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
    expect(conversationAPI).toHaveProperty('markMessageRead');
    expect(conversationAPI).toHaveProperty('toggleTyping');
    expect(conversationAPI).toHaveProperty('mute');
    expect(conversationAPI).toHaveProperty('meta');
    expect(conversationAPI).toHaveProperty('sendEmailTranscript');
  });
});
