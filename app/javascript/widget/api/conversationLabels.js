import { API } from 'widget/helpers/axios';
import { stripConversationToken } from 'widget/helpers/urlParamsHelper';

const buildUrl = endPoint =>
  `/api/v1/${endPoint}${stripConversationToken(window.location.search)}`;

export default {
  create(label) {
    return API.post(buildUrl('widget/labels'), { label });
  },
  destroy(label) {
    return API.delete(buildUrl(`widget/labels/${label}`));
  },
};
