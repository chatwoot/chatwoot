import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

export const getAvailableAgents = async () => {
  const urlData = endPoints.getAvailableAgents();
  const result = await API.get(urlData.url);
  return result;
};
