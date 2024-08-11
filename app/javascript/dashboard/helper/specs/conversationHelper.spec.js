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
      thumbnail:
        'http://0.0.0.0:3000/rails/active_storage/representations/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaHBEQT09IiwiZXhwIjpudWxsLCJwdXIiOiJibG9iX2lkIn19--7b95641540fadebc733ec9b42117d00bc09600be/eyJfcmFpbHMiOnsibWVzc2FnZSI6IkJBaDdCam9MY21WemFYcGxTU0lNTWpVd2VESTFNQVk2QmtWVSIsImV4cCI6bnVsbCwicHVyIjoidmFyaWF0aW9uIn19--c13bd5229b2a2a692444606e22f76ad61c634661/me.jpg',
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

const lastMessageInConversation = {
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
        messages: [conversationItem.messages[0]],
        last_non_activity_message: null,
      };
      expect(lastMessage(conversation)).toEqual(conversation.messages[0]);
    });

    it('should return message from store if store has latest message', () => {
      const conversation = {
        messages: [],
        last_non_activity_message: lastMessageInConversation,
      };
      expect(lastMessage(conversation)).toEqual(lastMessageInConversation);
    });

    it('should return last non activity message from store if api value is empty', () => {
      const conversation = {
        messages: [conversationItem.messages[0], conversationItem.messages[1]],
        last_non_activity_message: null,
      };
      expect(lastMessage(conversation)).toEqual(conversationItem.messages[1]);
    });

    it("should return last non activity message from store if store doesn't have any messages", () => {
      const conversation = {
        messages: [conversationItem.messages[1], conversationItem.messages[2]],
        last_non_activity_message: conversationItem.messages[0],
      };
      expect(lastMessage(conversation)).toEqual(conversation.messages[1]);
    });
  });
});
