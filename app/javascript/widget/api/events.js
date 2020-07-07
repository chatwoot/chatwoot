import { API } from 'widget/helpers/axios';
import { buildSearchParamsWithLocale } from '../helpers/urlParamsHelper';

export default {
  create(name) {
    const search = buildSearchParamsWithLocale(window.location.search);
    return API.post(`/api/v1/widget/events${search}`, { name });
  },
};
