import {
  findUndeliveredMessage,
  createTemporaryMessage,
  getNonDeletedMessages,
} from '../../conversation/helpers';

describe('#findUndeliveredMessage', () => {
  it('returns message objects if exist', () => {
    const conversation = {
      1: {
        id: 1,
        content: 'Hello',
        status: 'in_progress',
      },
      2: {
        id: 2,
        content: 'Hello',
        status: 'sent',
      },
      3: {
        id: 3,
        content: 'How may I help you',
        status: 'sent',
      },
    };
    expect(
      findUndeliveredMessage(conversation, { content: 'Hello' })
    ).toStrictEqual([{ id: 1, content: 'Hello', status: 'in_progress' }]);
  });
});

describe('#createTemporaryMessage', () => {
  it('returns message object', () => {
    const message = createTemporaryMessage({ content: 'hello' });
    expect(message.content).toBe('hello');
    expect(message.status).toBe('in_progress');
  });
  it('returns message object with reply to', () => {
    const message = createTemporaryMessage({
      content: 'hello',
      replyTo: 124,
    });
    expect(message.content).toBe('hello');
    expect(message.status).toBe('in_progress');
    expect(message.replyTo).toBe(124);
  });
});

describe('#getNonDeletedMessages', () => {
  it('returns non-deleted messages', () => {
    const messages = [
      {
        id: 1,
        content: 'Hello',
        content_attributes: {},
      },
      {
        id: 2,
        content: 'Hey',
        content_attributes: { deleted: true },
      },
      {
        id: 3,
        content: 'How may I help you',
        content_attributes: {},
      },
    ];
    expect(getNonDeletedMessages({ messages })).toStrictEqual([
      {
        id: 1,
        content: 'Hello',
        content_attributes: {},
      },
      {
        id: 3,
        content: 'How may I help you',
        content_attributes: {},
      },
    ]);
  });
});
