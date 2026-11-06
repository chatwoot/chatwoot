import { MESSAGE_TYPE } from 'shared/constants/messages';

/**
 * Whether the message can also be deleted for the customer on the inbox's channel.
 * @param {Object} inbox - Inbox with message_delete_window, the seconds after sending in which
 *   the channel allows deleting a message (null when the channel can't)
 * @param {Object} message - Message with messageType, private, sourceId and createdAt (in seconds)
 * @returns {boolean}
 */
export const canDeleteMessageOnChannel = (inbox, message) => {
  const deleteWindow = inbox.message_delete_window;
  if (!deleteWindow) return false;

  return (
    message.messageType === MESSAGE_TYPE.OUTGOING &&
    !message.private &&
    !!message.sourceId &&
    Date.now() / 1000 - message.createdAt < deleteWindow
  );
};
