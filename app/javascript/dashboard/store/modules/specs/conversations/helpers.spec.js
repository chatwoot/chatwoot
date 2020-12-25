import { findPendingMessageIndex } from '../../conversations/helpers';

describe('#findPendingMessageIndex', () => {
  it('returns the correct index of pending message with id', () => {
    const chat = {
      messages: [{ id: 1, status: 'progress' }],
    };
    const message = { echo_id: 1 };
    expect(findPendingMessageIndex(chat, message)).toEqual(0);
  });

  it('returns -1 if pending message with id is not present', () => {
    const chat = {
      messages: [{ id: 1, status: 'progress' }],
    };
    const message = { echo_id: 2 };
    expect(findPendingMessageIndex(chat, message)).toEqual(-1);
  });
});

describe('#addOrUpdateChat', () => {
  it('returns the correct index of pending message with id', () => {
    const chat = {
      messages: [{ id: 1, status: 'progress' }],
    };
    const message = { echo_id: 1 };
    expect(findPendingMessageIndex(chat, message)).toEqual(0);
  });

  it('returns -1 if pending message with id is not present', () => {
    const chat = {
      messages: [{ id: 1, status: 'progress' }],
    };
    const message = { echo_id: 2 };
    expect(findPendingMessageIndex(chat, message)).toEqual(-1);
  });
});
