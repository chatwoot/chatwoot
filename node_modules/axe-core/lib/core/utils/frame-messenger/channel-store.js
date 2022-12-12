import assert from '../assert';

const channels = {};

export function storeReplyHandler(
  channelId,
  replyHandler,
  sendToParent = true
) {
  assert(
    !channels[channelId],
    `A replyHandler already exists for this message channel.`
  );
  channels[channelId] = { replyHandler, sendToParent };
}

export function getReplyHandler(topic) {
  return channels[topic];
}

export function deleteReplyHandler(channelId) {
  delete channels[channelId];
}
