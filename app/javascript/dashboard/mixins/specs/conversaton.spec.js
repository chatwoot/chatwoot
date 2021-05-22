import conversationMixin from '../conversations';
import conversationFixture from './conversationFixtures';
import commonHelpers from '../../helper/commons';
commonHelpers();

describe('#conversationMixin', () => {
  it('should return unread message count 2 if conversation is passed', () => {
    expect(
      conversationMixin.methods.unreadMessagesCount(conversationFixture)
    ).toEqual(2);
  });
  it('should return last message if conversation is passed', () => {
    const lastMessage = {
      id: 438100,
      content: 'Hey',
      account_id: 1,
      inbox_id: 37,
      conversation_id: 5815,
      message_type: 0,
      created_at: 1621145476,
      updated_at: '2021-05-16T05:48:43.910Z',
      private: false,
      status: 'sent',
      source_id: null,
      content_type: 'text',
      content_attributes: {},
      sender_type: null,
      sender_id: null,
      external_source_ids: {},
    };
    expect(conversationMixin.methods.lastMessage(conversationFixture)).toEqual(
      lastMessage
    );
  });
  it('should return read messages if conversation is passed', () => {
    const readMessages = [
      {
        id: 438072,
        content: 'Campaign after 5 seconds',
        account_id: 1,
        inbox_id: 37,
        conversation_id: 5811,
        message_type: 1,
        created_at: 1620980262,
        updated_at: '2021-05-14T08:17:42.041Z',
        private: false,
        status: 'sent',
        source_id: null,
        content_type: null,
        content_attributes: {},
        sender_type: 'User',
        sender_id: 1,
        external_source_ids: {},
      },
    ];
    expect(conversationMixin.methods.readMessages(conversationFixture)).toEqual(
      readMessages
    );
  });
  it('should return read messages if conversation is passed', () => {
    const unReadMessages = [
      {
        id: 4382131101,
        content: 'Hello',
        account_id: 1,
        inbox_id: 37,
        conversation_id: 5815,
        message_type: 0,
        created_at: 1621145476,
        updated_at: '2021-05-16T05:48:43.910Z',
        private: false,
        status: 'sent',
        source_id: null,
        content_type: 'text',
        content_attributes: {},
        sender_type: null,
        sender_id: null,
        external_source_ids: {},
      },
      {
        id: 438100,
        content: 'Hey',
        account_id: 1,
        inbox_id: 37,
        conversation_id: 5815,
        message_type: 0,
        created_at: 1621145476,
        updated_at: '2021-05-16T05:48:43.910Z',
        private: false,
        status: 'sent',
        source_id: null,
        content_type: 'text',
        content_attributes: {},
        sender_type: null,
        sender_id: null,
        external_source_ids: {},
      },
    ];
    expect(
      conversationMixin.methods.unReadMessages(conversationFixture)
    ).toEqual(unReadMessages);
  });
});
