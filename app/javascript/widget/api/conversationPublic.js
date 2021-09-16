import { API } from 'widget/helpers/axios';

const buildUrl = endPoint => `/api/v1/${endPoint}${window.location.search}`;

/*
 *  Refer: https://www.chatwoot.com/developers/api#tag/Conversations-API
 */

export default {
  create(inboxIdentifier, contactIdentifier) {
    return API.post(
      buildUrl(
        `inboxes/${inboxIdentifier}/contacts/${contactIdentifier}/conversations`
      )
    );
  },

  get(inboxIdentifier, contactIdentifier) {
    return API.get(
      buildUrl(
        `inboxes/${inboxIdentifier}/contacts/${contactIdentifier}/conversations`
      )
    );
  },

  update(inboxIdentifier, contactIdentifier, userObject) {
    return API.patch(
      buildUrl(`inboxes/${inboxIdentifier}/contacts/${contactIdentifier}`),
      {
        ...userObject,
      }
    );
  },
};
