import { API } from 'widget/helpers/axios';

const buildUrl = endPoint => `/api/v1/${endPoint}${window.location.search}`;

export default {
  get() {
    return API.get(buildUrl('widget/contact'));
  },
  update(userObject) {
    return API.patch(buildUrl('widget/contact'), userObject);
  },
  setUser(identifier, userObject) {
    return API.patch(buildUrl('widget/contact/set_user'), {
      identifier,
      ...userObject,
    });
  },
  setCustomAttributes(customAttributes = {}) {
    return API.patch(buildUrl('widget/contact'), {
      custom_attributes: customAttributes,
    });
  },
  deleteCustomAttribute(customAttribute) {
    return API.post(buildUrl('widget/contact/destroy_custom_attributes'), {
      custom_attributes: [customAttribute],
    });
  },
};
