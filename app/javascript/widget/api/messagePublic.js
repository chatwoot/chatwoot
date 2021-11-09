import { API } from 'widget/helpers/axios';

const buildUrl = endPoint =>
  `/api/v1/widget/${endPoint}${window.location.search}`;

/*
 *  Refer: https://www.chatwoot.com/developers/api#tag/Messages-API
 */

export default {
  create(conversationId, content, echoId) {
    return API.post(buildUrl(`conversations/${conversationId}/messages`), {
      content,
      echo_id: echoId,
    });
  },

  createAttachment(conversationId, attachmentParams) {
    return API.post(
      buildUrl(`conversations/${conversationId}/messages`),
      attachmentParams
    );
  },

  get(conversationId, beforeId) {
    return API.get(buildUrl(`conversations/${conversationId}/messages`), {
      params: { before: beforeId },
    });
  },

  update(conversationId, messageObject) {
    const { id: messageId } = messageObject;
    return API.patch(
      buildUrl(`conversations/${conversationId}/messages/${messageId}`),
      {
        ...messageObject,
      }
    );
  },
};
