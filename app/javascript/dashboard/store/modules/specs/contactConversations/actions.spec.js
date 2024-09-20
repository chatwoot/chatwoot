import axios from 'axios';
import {
  actions,
  createMessagePayload,
  createConversationPayload,
  createWhatsAppConversationPayload,
} from '../../contactConversations';
import * as types from '../../../mutation-types';
import conversationList from './fixtures';

const commit = vi.fn();
global.axios = axios;
vi.mock('axios');

describe('#actions', () => {
  describe('#get', () => {
    it('sends correct actions if API is success', async () => {
      axios.get.mockResolvedValue({ data: { payload: conversationList } });
      await actions.get({ commit }, 1);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, { isFetching: true }],

        [
          types.default.SET_CONTACT_CONVERSATIONS,
          { id: 1, data: conversationList },
        ],
        [
          types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG,
          { isFetching: false },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.get.mockRejectedValue({ message: 'Incorrect header' });
      await actions.get({ commit });
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, { isFetching: true }],
        [
          types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG,
          { isFetching: false },
        ],
      ]);
    });
  });

  describe('#create', () => {
    it('sends correct actions if API is success', async () => {
      axios.post.mockResolvedValue({ data: conversationList[0] });
      await actions.create(
        { commit },
        {
          params: {
            inboxId: 1,
            message: { content: 'hi' },
            contactId: 4,
            sourceId: 5,
            mailSubject: 'Mail Subject',
            assigneeId: 6,
            files: [],
          },
          isFromWhatsApp: false,
        }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, { isCreating: true }],
        [
          types.default.ADD_CONTACT_CONVERSATION,
          { id: 4, data: conversationList[0] },
        ],
        [
          types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG,
          { isCreating: false },
        ],
      ]);
    });
    it('sends correct actions with files if API is success', async () => {
      axios.post.mockResolvedValue({ data: conversationList[0] });
      await actions.create(
        { commit },
        {
          params: {
            inboxId: 1,
            message: { content: 'hi' },
            contactId: 4,
            sourceId: 5,
            mailSubject: 'Mail Subject',
            assigneeId: 6,
            files: ['file1.pdf', 'file2.jpg'],
          },
          isFromWhatsApp: false,
        }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, { isCreating: true }],
        [
          types.default.ADD_CONTACT_CONVERSATION,
          { id: 4, data: conversationList[0] },
        ],
        [
          types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG,
          { isCreating: false },
        ],
      ]);
    });
    it('sends correct actions actions if API is success for whatsapp conversation', async () => {
      axios.post.mockResolvedValue({ data: conversationList[0] });
      await actions.create(
        { commit },
        {
          params: {
            inboxId: 1,
            message: {
              content: 'hi',
              template_params: {
                name: 'hello_world',
                category: 'MARKETING',
                language: 'en_US',
                processed_params: {},
              },
            },
            contactId: 4,
            sourceId: 5,
            assigneeId: 6,
          },
          isFromWhatsApp: true,
        }
      );
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, { isCreating: true }],
        [
          types.default.ADD_CONTACT_CONVERSATION,
          { id: 4, data: conversationList[0] },
        ],
        [
          types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG,
          { isCreating: false },
        ],
      ]);
    });
    it('sends correct actions if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.create(
          { commit },
          {
            params: {
              inboxId: 1,
              message: { content: 'hi' },
              contactId: 4,
              assigneeId: 6,
              sourceId: 5,
              mailSubject: 'Mail Subject',
            },
            isFromWhatsApp: false,
          }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, { isCreating: true }],
        [
          types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG,
          { isCreating: false },
        ],
      ]);
    });
    it('sends correct actions with files if API is error', async () => {
      axios.post.mockRejectedValue({ message: 'Incorrect header' });
      await expect(
        actions.create(
          { commit },
          {
            params: {
              inboxId: 1,
              message: { content: 'hi' },
              contactId: 4,
              sourceId: 5,
              mailSubject: 'Mail Subject',
              assigneeId: 6,
              files: ['file1.pdf', 'file2.jpg'],
            },
            isFromWhatsApp: false,
          }
        )
      ).rejects.toThrow(Error);
      expect(commit.mock.calls).toEqual([
        [types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG, { isCreating: true }],
        [
          types.default.SET_CONTACT_CONVERSATIONS_UI_FLAG,
          { isCreating: false },
        ],
      ]);
    });
  });
});

describe('createMessagePayload', () => {
  it('creates message payload with cc and bcc emails', () => {
    const payload = new FormData();
    const message = {
      content: 'Test message content',
      cc_emails: 'cc@example.com',
      bcc_emails: 'bcc@example.com',
    };

    createMessagePayload(payload, message);

    expect(payload.get('message[content]')).toBe(message.content);
    expect(payload.get('message[cc_emails]')).toBe(message.cc_emails);
    expect(payload.get('message[bcc_emails]')).toBe(message.bcc_emails);
  });

  it('creates message payload without cc and bcc emails', () => {
    const payload = new FormData();
    const message = {
      content: 'Test message content',
    };

    createMessagePayload(payload, message);

    expect(payload.get('message[content]')).toBe(message.content);
    expect(payload.get('message[cc_emails]')).toBeNull();
    expect(payload.get('message[bcc_emails]')).toBeNull();
  });
});

describe('createConversationPayload', () => {
  it('creates conversation payload with message and attachments', () => {
    const options = {
      params: {
        inboxId: '1',
        message: {
          content: 'Test message content',
        },
        sourceId: '12',
        mailSubject: 'Test Subject',
        assigneeId: '123',
      },
      contactId: '23',
      files: ['file1.pdf', 'file2.jpg'],
    };

    const payload = createConversationPayload(options);

    expect(payload.get('message[content]')).toBe(
      options.params.message.content
    );
    expect(payload.get('inbox_id')).toBe(options.params.inboxId);
    expect(payload.get('contact_id')).toBe(options.contactId);
    expect(payload.get('source_id')).toBe(options.params.sourceId);
    expect(payload.get('additional_attributes[mail_subject]')).toBe(
      options.params.mailSubject
    );
    expect(payload.get('assignee_id')).toBe(options.params.assigneeId);
    expect(payload.getAll('message[attachments][]')).toEqual(options.files);
  });

  it('creates conversation payload with message and without attachments', () => {
    const options = {
      params: {
        inboxId: '1',
        message: {
          content: 'Test message content',
        },
        sourceId: '12',
        mailSubject: 'Test Subject',
        assigneeId: '123',
      },
      contactId: '23',
    };

    const payload = createConversationPayload(options);

    expect(payload.get('message[content]')).toBe(
      options.params.message.content
    );
    expect(payload.get('inbox_id')).toBe(options.params.inboxId);
    expect(payload.get('contact_id')).toBe(options.contactId);
    expect(payload.get('source_id')).toBe(options.params.sourceId);
    expect(payload.get('additional_attributes[mail_subject]')).toBe(
      options.params.mailSubject
    );
    expect(payload.get('assignee_id')).toBe(options.params.assigneeId);
    expect(payload.getAll('message[attachments][]')).toEqual([]);
  });
});

describe('createWhatsAppConversationPayload', () => {
  it('creates conversation payload with message', () => {
    const options = {
      params: {
        inboxId: '1',
        message: {
          content: 'Test message content',
        },
        sourceId: '12',
        assigneeId: '123',
      },
    };

    const payload = createWhatsAppConversationPayload(options);

    expect(payload.message).toBe(options.params.message);
    expect(payload.inbox_id).toBe(options.params.inboxId);
    expect(payload.source_id).toBe(options.params.sourceId);
    expect(payload.assignee_id).toBe(options.params.assigneeId);
  });
});
