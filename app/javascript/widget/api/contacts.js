import { API } from 'widget/helpers/axios';

const buildUrl = endPoint => `/api/v1/${endPoint}${window.location.search}`;

export default {
  create(inboxIdentifier, userObject) {
    return API.post(buildUrl(`inboxes/${inboxIdentifier}/contacts`), {
      ...userObject,
    });
  },

  get(inboxIdentifier, contactIdentifier) {
    return API.get(
      buildUrl(`inboxes/${inboxIdentifier}/contacts/${contactIdentifier}`)
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

  setCustomAttibutes(customAttributes = {}) {
    return API.patch(buildUrl('widget/contact'), {
      custom_attributes: customAttributes,
    });
  },
};
