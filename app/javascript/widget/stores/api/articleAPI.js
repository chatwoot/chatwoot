import { API } from 'widget/helpers/axios';

export default {
  index: params => {
    const url = `/hc/${params.slug}/${params.locale}/articles.json`;
    const urlParams = {
      page: 1,
      sort: 'views',
      status: 1,
    };
    return API.get(url, { params: urlParams });
  },
};
