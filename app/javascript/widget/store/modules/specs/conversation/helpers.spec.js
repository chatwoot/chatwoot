import {
  findUndeliveredMessage,
  createTemporaryMessage,
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
});
