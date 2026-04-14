/* eslint no-param-reassign: 0 */

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

export const isEmptyObject = obj =>
  Object.keys(obj).length === 0 && obj.constructor === Object;

export const isJSONValid = value => {
  try {
    JSON.parse(value);
  } catch (e) {
    return false;
  }
  return true;
};

export const getTypingUsersText = (users = []) => {
  const count = users.length;
  const [firstUser, secondUser] = users;

  if (count === 1) {
    return ['TYPING.ONE', { user: firstUser.name }];
  }

  if (count === 2) {
    return [
      'TYPING.TWO',
      { user: firstUser.name, secondUser: secondUser.name },
    ];
  }

  return ['TYPING.MULTIPLE', { user: firstUser.name, count: count - 1 }];
};

export const createPendingMessage = data => {
  const timestamp = Math.floor(new Date().getTime() / 1000);
  const tempMessageId = getUuid();
  const { message, file } = data;
  const tempAttachments = [{ id: tempMessageId }];
  const pendingMessage = {
    ...data,
    content: message || null,
    id: tempMessageId,
    echo_id: tempMessageId,
    status: MESSAGE_STATUS.PROGRESS,
    created_at: timestamp,
    message_type: MESSAGE_TYPE.OUTGOING,
    conversation_id: data.conversationId,
    attachments: file ? tempAttachments : null,
  };

  return pendingMessage;
};

export const convertToAttributeSlug = text => {
  return text
    .toLowerCase()
    .replace(/[^\w ]+/g, '')
    .replace(/ +/g, '_');
};

export const convertToCategorySlug = text => {
  return text
    .toLowerCase()
    .replace(/[^\w ]+/g, '')
    .replace(/ +/g, '-');
};

export const convertToPortalSlug = text => {
  return text
    .toLowerCase()
    .replace(/[^\w ]+/g, '')
    .replace(/ +/g, '-');
};

/**
 * Strip curly braces, commas and leading/trailing whitespace from a search key.
 * Eg. "{{contact.name}}," => "contact.name"
 * @param {string} searchKey
 * @returns {string}
 */
export const sanitizeVariableSearchKey = (searchKey = '') => {
  return searchKey
    .replace(/[{}]/g, '') // remove all curly braces
    .replace(/,/g, '') // remove commas
    .trim();
};

/**
 * Convert underscore-separated string to title case.
 * Eg. "round_robin" => "Round Robin"
 * @param {string} str
 * @returns {string}
 */
export const formatToTitleCase = str => {
  return (
    str
      ?.replace(/_/g, ' ')
      .replace(/\b\w/g, l => l.toUpperCase())
      .trim() || ''
  );
};
