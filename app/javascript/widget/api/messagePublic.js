import { API } from 'widget/helpers/axios';

const buildUrl = endPoint => `/api/v1/${endPoint}${window.location.search}`;

/*
 *  Refer: https://www.chatwoot.com/developers/api#tag/Messages-API
 */

export default {
  create(inboxIdentifier, contactIdentifier, conversationId, content, echoId) {
    return API.post(
      buildUrl(
        `inboxes/${inboxIdentifier}/contacts/${contactIdentifier}/conversations/${conversationId}/messages`
      ),
      { content, echo_id: echoId }
    );
  },

  get(inboxIdentifier, contactIdentifier, conversationId) {
    return API.get(
      buildUrl(
        `inboxes/${inboxIdentifier}/contacts/${contactIdentifier}/conversations/${conversationId}/messages`
      )
    );
  },

  update(inboxIdentifier, contactIdentifier, conversationId, messageObject) {
    const { id: messageId } = messageObject;
    return API.patch(
      buildUrl(
        `inboxes/${inboxIdentifier}/contacts/${contactIdentifier}/conversations/${conversationId}/messages/${messageId}`
      ),
      {
        ...messageObject,
      }
    );
  },
};
