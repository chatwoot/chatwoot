import { v4 as createUuid } from '../uuid';

const messageIds = [];

export function createMessageId() {
  const uuid = `${createUuid()}:${createUuid()}`;
  // Prevent repeats
  if (messageIds.includes(uuid)) {
    return createMessageId();
  }

  messageIds.push(uuid);
  return uuid;
}

export function isNewMessage(uuid) {
  if (messageIds.includes(uuid)) {
    return false;
  }
  messageIds.push(uuid);
  return true;
}
