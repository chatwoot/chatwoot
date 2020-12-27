/* eslint no-param-reassign: 0 */
const groupBy = require('lodash.groupby');
import { formatUnixDate } from 'shared/helpers/DateHelper';
import { isASubmittedFormMessage } from 'shared/helpers/MessageTypeHelper';
import getUuid from 'widget/helpers/uuid';
import { MESSAGE_STATUS, MESSAGE_TYPE } from 'shared/constants/messages';

export default () => {
  if (!Array.prototype.last) {
    Object.assign(Array.prototype, {
      last() {
        return this[this.length - 1];
      },
    });
  }
};

export const getTypingUsersText = (users = []) => {
  const count = users.length;
  if (count === 1) {
    const [user] = users;
    return `${user.name} is typing`;
  }

  if (count === 2) {
    const [first, second] = users;
    return `${first.name} and ${second.name} are typing`;
  }

  const [user] = users;
  const rest = users.length - 1;
  return `${user.name} and ${rest} others are typing`;
};

export const createPendingMessage = data => {
  const timestamp = Math.floor(new Date().getTime() / 1000);
  const tempMessageId = getUuid();
  const pendingMessage = {
    ...data,
    content: data.message,
    id: tempMessageId,
    echo_id: tempMessageId,
    status: MESSAGE_STATUS.PROGRESS,
    created_at: timestamp,
    message_type: MESSAGE_TYPE.OUTGOING,
    conversation_id: data.conversationId,
  };
  return pendingMessage;
};

export const createPendingAttachment = data => {
  const [conversationId, { isPrivate = false }] = data;
  const timestamp = Math.floor(new Date().getTime() / 1000);
  const tempMessageId = getUuid();
  const pendingMessage = {
    id: tempMessageId,
    echo_id: tempMessageId,
    status: MESSAGE_STATUS.PROGRESS,
    created_at: timestamp,
    message_type: MESSAGE_TYPE.OUTGOING,
    conversation_id: conversationId,
    attachments: [
      {
        id: tempMessageId,
      },
    ],
    private: isPrivate,
    content: null,
  };
  return pendingMessage;
};

const getSenderName = message => (message.sender ? message.sender.name : '');

const shouldShowAvatar = (message, nextMessage) => {
  const currentSender = getSenderName(message);
  const nextSender = getSenderName(nextMessage);

  return (
    currentSender !== nextSender ||
    message.message_type !== nextMessage.message_type ||
    isASubmittedFormMessage(nextMessage)
  );
};

const groupConversationBySender = conversationsForADate =>
  conversationsForADate.map((message, index) => {
    let showAvatar = false;
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

export const getGroupedConversation = ({ conversations }) => {
  const conversationGroupedByDate = groupBy(
    Object.values(conversations),
    message => formatUnixDate(message.created_at)
  );
  return Object.keys(conversationGroupedByDate).map(date => ({
    date,
    messages: groupConversationBySender(conversationGroupedByDate[date]),
  }));
};
