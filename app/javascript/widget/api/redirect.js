import { API } from 'widget/helpers/axios';

const buildUrl = endPoint => `/api/v1/${endPoint}${window.location.search}`;

export default {
  resolve(token) {
    return API.post(buildUrl('widget/redirect_token'), { token });
  },
};
