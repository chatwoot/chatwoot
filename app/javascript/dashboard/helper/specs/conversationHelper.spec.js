import {
  filterDuplicateSourceMessages,
  lastMessage,
  readMessages,
  unReadMessages,
} from '../conversationHelper';

const conversationItem = {
  meta: {
    sender: {
      additional_attributes: {
        created_at_ip: '127.0.0.1',
      },
      availability_status: 'offline',
      email: null,
      id: 5017687,
      name: 'long-flower-143',
      phone_number: null,
      thumbnail: '',
      custom_attributes: {},
    },
    channel: 'Channel::WebWidget',
    assignee: {
      account_id: 1,
      availability_status: 'offline',
      confirmed: true,
      email: 'muhsin@chatwoot.com',
      available_name: 'Muhsin Keloth',
      id: 21,
      name: 'Muhsin Keloth',
      role: 'administrator',
      thumbnail: 'http://example.com/image.jpg',
    },
  },
  id: 5815,
  messages: [
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
  ],
  inbox_id: 37,
  status: 'open',
  muted: false,
  can_reply: true,
  timestamp: 1621144123,
  contact_last_seen_at: 0,
  agent_last_seen_at: 1621144123,
  unread_count: 0,
  additional_attributes: {
    browser: {
      device_name: 'Unknown',
      browser_name: 'Chrome',
      platform_name: 'macOS',
      browser_version: '90.0.4430.212',
      platform_version: '10.15.7',
    },
    widget_language: null,
    browser_language: 'en',
  },
  account_id: 1,
  labels: [],
};

const readMessagesArray = [
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

const unReadMessagesArray = [
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
        readMessages(
          conversationItem.messages,
          conversationItem.agent_last_seen_at
        )
      ).toEqual(readMessagesArray);
    });
  });

  describe('#unReadMessages', () => {
    it('should return unread messages if conversation is passed', () => {
      expect(
        unReadMessages(
          conversationItem.messages,
          conversationItem.agent_last_seen_at
        )
      ).toEqual(unReadMessagesArray);
    });
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
      expect(lastMessage(conversation)).toEqual(messages[messages.length - 1]);
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
      expect(lastMessage(conversation)).toEqual(
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
      expect(lastMessage(conversation)).toEqual(conversation.messages[0]);
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
      expect(lastMessage(conversation)).toEqual(conversation.messages[1]);
    });
  });
});
