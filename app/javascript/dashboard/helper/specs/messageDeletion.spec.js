import { canDeleteMessageOnChannel } from 'dashboard/helper/messageDeletion';
import { MESSAGE_TYPE } from 'shared/constants/messages';

const DELETE_WINDOW = 60 * 60;

const now = () => Math.floor(Date.now() / 1000);

const inbox = { message_delete_window: DELETE_WINDOW };

const deliveredMessage = (overrides = {}) => ({
  messageType: MESSAGE_TYPE.OUTGOING,
  private: false,
  sourceId: '101',
  createdAt: now() - 60,
  ...overrides,
});

describe('canDeleteMessageOnChannel', () => {
  it('returns true for a delivered outgoing message inside the delete window', () => {
    expect(canDeleteMessageOnChannel(inbox, deliveredMessage())).toBe(true);
  });

  it('returns false once the delete window has passed', () => {
    const message = deliveredMessage({ createdAt: now() - DELETE_WINDOW - 60 });
    expect(canDeleteMessageOnChannel(inbox, message)).toBe(false);
  });

  it('returns false for incoming messages', () => {
    const message = deliveredMessage({ messageType: MESSAGE_TYPE.INCOMING });
    expect(canDeleteMessageOnChannel(inbox, message)).toBe(false);
  });

  it('returns false for private notes', () => {
    const message = deliveredMessage({ private: true });
    expect(canDeleteMessageOnChannel(inbox, message)).toBe(false);
  });

  it('returns false for messages that never reached the channel', () => {
    const message = deliveredMessage({ sourceId: '' });
    expect(canDeleteMessageOnChannel(inbox, message)).toBe(false);
  });

  it('returns false for inboxes whose channel cannot delete messages', () => {
    expect(
      canDeleteMessageOnChannel(
        { message_delete_window: null },
        deliveredMessage()
      )
    ).toBe(false);
    expect(canDeleteMessageOnChannel({}, deliveredMessage())).toBe(false);
  });
});
