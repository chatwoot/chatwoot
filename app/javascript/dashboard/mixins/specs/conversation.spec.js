import conversationMixin, {
  filterDuplicateSourceMessages,
} from '../conversations';
import conversationFixture from './conversationFixtures';
import commonHelpers from '../../helper/commons';
commonHelpers();

describe('#filterDuplicateSourceMessages', () => {
  it('returns messages without duplicate source_id and all messages without source_id', () => {
    expect(
      filterDuplicateSourceMessages([
        { source_id: null, id: 1 },
        { source_id: '', id: 2 },
        { id: 3 },
        { source_id: 'wa_1', id: 4 },
        { source_id: 'wa_1', id: 5 },
        { source_id: 'wa_1', id: 6 },
        { source_id: 'wa_2', id: 7 },
        { source_id: 'wa_2', id: 8 },
        { source_id: 'wa_3', id: 9 },
      ])
    ).toEqual([
      { source_id: null, id: 1 },
      { source_id: '', id: 2 },
      { id: 3 },
      { source_id: 'wa_1', id: 4 },
      { source_id: 'wa_2', id: 7 },
      { source_id: 'wa_3', id: 9 },
    ]);
  });
});

describe('#conversationMixin', () => {
  it('should return read messages if conversation is passed', () => {
    expect(
      conversationMixin.methods.readMessages(
        conversationFixture.conversation.messages,
        conversationFixture.conversation.agent_last_seen_at
      )
    ).toEqual(conversationFixture.readMessages);
  });
  it('should return read messages if conversation is passed', () => {
    expect(
      conversationMixin.methods.unReadMessages(
        conversationFixture.conversation.messages,
        conversationFixture.conversation.agent_last_seen_at
      )
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
