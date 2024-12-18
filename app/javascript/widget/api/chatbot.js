import { API } from 'widget/helpers/axios';
import { buildSearchParamsWithLocale } from '../helpers/urlParamsHelper';

export default {
  connectWithTeam: messageId => {
    const search = buildSearchParamsWithLocale(window.location.search);
    const urlData = {
      url: `/api/v1/widget/chatbots/connect_with_team${search}`,
    };
    return API.post(urlData.url, { message_id: messageId });
  },
};
