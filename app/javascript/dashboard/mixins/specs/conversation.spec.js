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

  describe('#lastMessage', () => {
    it("should return last activity message if both api and store doesn't have other messages", () => {
      const conversation = {
        messages: [
          { id: 1, created_at: 1654333, message_type: 2, content: 'Hey' },
        ],
        last_non_activity_message: null,
      };
      const { messages } = conversation;
      expect(conversationMixin.methods.lastMessage(conversation)).toEqual(
        messages[messages.length - 1]
      );
    });

    it('should return message from store if store has latest message', () => {
      const conversation = {
        messages: [],
        last_non_activity_message: {
          id: 2,
          created_at: 1654334,
          message_type: 2,
          content: 'Hey',
        },
      };
      expect(conversationMixin.methods.lastMessage(conversation)).toEqual(
        conversation.last_non_activity_message
      );
    });

    it('should return last non activity message from store if api value is empty', () => {
      const conversation = {
        messages: [
          {
            id: 1,
            created_at: 1654333,
            message_type: 1,
            content: 'Outgoing Message',
          },
          { id: 2, created_at: 1654334, message_type: 2, content: 'Hey' },
        ],
        last_non_activity_message: null,
      };
      expect(conversationMixin.methods.lastMessage(conversation)).toEqual(
        conversation.messages[0]
      );
    });

    it("should return last non activity message from store if store doesn't have any messages", () => {
      const conversation = {
        messages: [
          {
            id: 1,
            created_at: 1654333,
            message_type: 1,
            content: 'Outgoing Message',
          },
          {
            id: 3,
            created_at: 1654335,
            message_type: 0,
            content: 'Incoming Message',
          },
        ],
        last_non_activity_message: {
          id: 2,
          created_at: 1654334,
          message_type: 2,
          content: 'Hey',
        },
      };
      expect(conversationMixin.methods.lastMessage(conversation)).toEqual(
        conversation.messages[1]
      );
    });
  });
});
