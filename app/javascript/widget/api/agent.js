import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export const getAvailableAgents = async websiteToken => {
  const urlData = endPoints.getAvailableAgents(websiteToken);
  const result = await API.get(urlData.url, { params: urlData.params });
  return result;
};
