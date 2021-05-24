import conversationMixin from '../conversations';
import conversationFixture from './conversationFixtures';
import commonHelpers from '../../helper/commons';
commonHelpers();

describe('#conversationMixin', () => {
  it('should return unread message count 2 if conversation is passed', () => {
    expect(
      conversationMixin.methods.unreadMessagesCount(
        conversationFixture.conversation
      )
    ).toEqual(2);
  });
  it('should return last message if conversation is passed', () => {
    expect(
      conversationMixin.methods.lastMessage(conversationFixture.conversation)
    ).toEqual(conversationFixture.lastMessage);
  });
  it('should return read messages if conversation is passed', () => {
    expect(
      conversationMixin.methods.readMessages(conversationFixture.conversation)
    ).toEqual(conversationFixture.readMessages);
  });
  it('should return read messages if conversation is passed', () => {
    expect(
      conversationMixin.methods.unReadMessages(conversationFixture.conversation)
    ).toEqual(conversationFixture.unReadMessages);
  });
});
