import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

const getCampaigns = async websiteToken => {
  const urlData = endPoints.getCampaigns(websiteToken);
  const result = await API.get(urlData.url, { params: urlData.params });
  return result;
};

export { getCampaigns };
