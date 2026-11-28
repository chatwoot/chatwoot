import { MESSAGE_TYPE } from 'shared/constants/messages';

/**
 * Whether the message can also be deleted for the customer on the inbox's channel.
 * @param {Object} inbox - Inbox with message_delete_window, the seconds after sending in which
 *   the channel allows deleting a message (null when the channel can't)
 * @param {Object} message - Message with messageType, private, sourceId and createdAt (in seconds)
 * @param {number} now - Time to check the delete window against, in milliseconds
 * @returns {boolean}
 */
export const canDeleteMessageOnChannel = (inbox, message, now = Date.now()) => {
  const deleteWindow = inbox.message_delete_window;
  if (!deleteWindow) return false;

  return (
    message.messageType === MESSAGE_TYPE.OUTGOING &&
    !message.private &&
    !!message.sourceId &&
    now / 1000 - message.createdAt < deleteWindow
  );
};
