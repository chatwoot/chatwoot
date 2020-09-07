import { API } from 'widget/helpers/axios';

const buildUrl = endPoint => `/api/v1/${endPoint}${window.location.search}`;

export default {
  update(identifier, userObject) {
    return API.patch(buildUrl('widget/contact'), {
      identifier,
      ...userObject,
    });
  },
  setCustomAttibutes(customAttributes = {}) {
    return API.patch(buildUrl('widget/contact'), {
      custom_attributes: customAttributes,
    });
  },
};
