import endPoints from 'widget/api/endPoints';
import { API } from 'widget/helpers/axios';

const getCampaigns = async websiteToken => {
  const urlData = endPoints.getCampaigns(websiteToken);
  return API.get(urlData.url, { params: urlData.params });
};

const triggerCampaign = async ({
  campaignId,
  websiteToken,
  customAttributes,
}) => {
  const urlData = endPoints.triggerCampaign({
    websiteToken,
    campaignId,
    customAttributes,
  });
  await API.post(
    urlData.url,
    { ...urlData.data },
    {
      params: urlData.params,
    }
  );
};
export { getCampaigns, triggerCampaign };
