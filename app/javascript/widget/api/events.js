import { API } from 'widget/helpers/axios';

export default {
  create(name) {
    return API.post(`/api/v1/widget/events${window.location.search}`, { name });
  },
};
