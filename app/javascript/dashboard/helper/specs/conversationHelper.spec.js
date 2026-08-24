import {
  filterDuplicateSourceMessages,
  getLastMessage,
  getReadMessages,
  getUnreadMessages,
  getVisibleUnreadCount,
} from '../conversationHelper';
import {
  conversationData,
  lastMessageData,
  readMessagesData,
  unReadMessagesData,
} from './fixtures/conversationFixtures';

describe('conversationHelper', () => {
  describe('#filterDuplicateSourceMessages', () => {
    it('returns messages without duplicate source_id and all messages without source_id', () => {
      const input = [
        { source_id: null, id: 1 },
        { source_id: '', id: 2 },
        { id: 3 },
        { source_id: 'wa_1', id: 4 },
        { source_id: 'wa_1', id: 5 },
        { source_id: 'wa_1', id: 6 },
        { source_id: 'wa_2', id: 7 },
        { source_id: 'wa_2', id: 8 },
        { source_id: 'wa_3', id: 9 },
      ];
      const expected = [
        { source_id: null, id: 1 },
        { source_id: '', id: 2 },
        { id: 3 },
        { source_id: 'wa_1', id: 4 },
        { source_id: 'wa_2', id: 7 },
        { source_id: 'wa_3', id: 9 },
      ];
      expect(filterDuplicateSourceMessages(input)).toEqual(expected);
    });
  });

  describe('#readMessages', () => {
    it('should return read messages if conversation is passed', () => {
      expect(
        getReadMessages(
          conversationData.messages,
          conversationData.agent_last_seen_at
        )
      ).toEqual(readMessagesData);
    });
  });

  describe('#unReadMessages', () => {
    it('should return unread messages if conversation is passed', () => {
      expect(
        getUnreadMessages(
          conversationData.messages,
          conversationData.agent_last_seen_at
        )
      ).toEqual(unReadMessagesData);
    });
  });

  describe('#lastMessage', () => {
    it("should return last activity message if both api and store doesn't have other messages", () => {
      const testConversation = {
        messages: [conversationData.messages[0]],
        last_non_activity_message: null,
      };
      expect(getLastMessage(testConversation)).toEqual(
        testConversation.messages[0]
      );
    });

    it('should return message from store if store has latest message', () => {
      const testConversation = {
        messages: [],
        last_non_activity_message: lastMessageData,
      };
      expect(getLastMessage(testConversation)).toEqual(lastMessageData);
    });

    it('should return last non activity message from store if api value is empty', () => {
      const testConversation = {
        messages: [conversationData.messages[0], conversationData.messages[1]],
        last_non_activity_message: null,
      };
      expect(getLastMessage(testConversation)).toEqual(
        testConversation.messages[1]
      );
    });

    it("should return last non activity message from store if store doesn't have any messages", () => {
      const testConversation = {
        messages: [conversationData.messages[1], conversationData.messages[2]],
        last_non_activity_message: conversationData.messages[0],
      };
      expect(getLastMessage(testConversation)).toEqual(
        testConversation.messages[1]
      );
    });
  });

  describe('#getVisibleUnreadCount', () => {
    it('returns 0 when staff have already replied', () => {
      expect(
        getVisibleUnreadCount({
          unread_count: 9,
          waiting_since: 0,
          messages: [{ message_type: 1, private: false }],
        })
      ).toEqual(0);
    });

    it('returns 0 when the last message is a public outgoing reply', () => {
      expect(
        getVisibleUnreadCount({
          unread_count: 2,
          waiting_since: 1710000000,
          messages: [
            { message_type: 1, private: false, created_at: 1710000001 },
          ],
        })
      ).toEqual(0);
    });

    it('returns the stored unread count when the customer is still waiting', () => {
      expect(
        getVisibleUnreadCount({
          unread_count: 3,
          waiting_since: 1710000000,
          messages: [
            { message_type: 0, private: false, created_at: 1710000001 },
          ],
        })
      ).toEqual(3);
    });
  });
});
