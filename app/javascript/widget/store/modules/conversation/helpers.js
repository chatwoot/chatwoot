import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { isASubmittedFormMessage } from 'shared/helpers/MessageTypeHelper';

import getUuid from '../../../helpers/uuid';
export const createTemporaryMessage = ({ attachments, content, replyTo }) => {
  const timestamp = new Date().getTime() / 1000;
  return {
    id: getUuid(),
    content,
    attachments,
    status: 'in_progress',
    replyTo,
    created_at: timestamp,
    message_type: MESSAGE_TYPE.INCOMING,
  };
};

const getSenderIdentity = ({ sender }) =>
  sender ? `${sender.type}:${sender.id}` : '';

const shouldShowAvatar = (message, nextMessage) => {
  const currentSender = getSenderIdentity(message);
  const nextSender = getSenderIdentity(nextMessage);

  return (
    currentSender !== nextSender ||
    message.message_type !== nextMessage.message_type ||
    isASubmittedFormMessage(nextMessage)
  );
};

export const groupConversationBySender = conversationsForADate =>
  conversationsForADate.map((message, index) => {
    let showAvatar;
    const isLastMessage = index === conversationsForADate.length - 1;
    if (isASubmittedFormMessage(message)) {
      showAvatar = false;
    } else if (isLastMessage) {
      showAvatar = true;
    } else {
      const nextMessage = conversationsForADate[index + 1];
      showAvatar = shouldShowAvatar(message, nextMessage);
    }
    return { showAvatar, ...message };
  });

export const findUndeliveredMessage = (messageInbox, { content }) =>
  Object.values(messageInbox).filter(
    message => message.content === content && message.status === 'in_progress'
  );

export const getNonDeletedMessages = ({ messages }) => {
  return messages.filter(
    item => !(item.content_attributes && item.content_attributes.deleted)
  );
};

// A message the server has stored. A temporary message carries a uuid until the API answers,
// and a uuid is not a cursor the API can page from.
export const isPersisted = message => Number.isInteger(message.id);

// The store is keyed by message id, so Object.values iterates by id. Ids only follow time
// while messages are created in the order they happened; a backdated created_at breaks that.
// Stored messages are sorted by created_at, which is what the API pages by. The sort is
// stable and integer keys iterate in ascending order, so messages sharing a second stay in
// id order, the API's tiebreak.
// Temporary messages stay after every stored one, in the order they were sent: their
// created_at comes from the visitor's clock, not the server's, and comparing the two would
// move a message just sent above replies that already arrived when that clock is behind.
export const chronological = conversations => {
  const messages = Object.values(conversations);
  const stored = messages
    .filter(isPersisted)
    .sort((a, b) => (a.created_at ?? 0) - (b.created_at ?? 0));
  return [...stored, ...messages.filter(message => !isPersisted(message))];
};
