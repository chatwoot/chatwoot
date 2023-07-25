import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export const getMostReadArticles = async (websiteToken, slug, locale) => {
  const urlData = endPoints.getMostReadArticles(websiteToken, slug, locale);
  return API.get(urlData.url, { params: urlData.params });
};
