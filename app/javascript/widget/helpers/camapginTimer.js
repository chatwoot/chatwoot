import { triggerCampaign } from 'widget/api/campaign';
import { formatCampaigns, filterCampaigns } from './campaignHelper';
window.campaignTimers = [];
export const startCampaigns = async ({ allCampaigns, currentURL }) => {
  // Clear all campaign timers
  window.campaignTimers.forEach(timerId => {
    clearTimeout(timerId);
  });
  const formattedCampaigns = formatCampaigns({ campagins: allCampaigns });
  const filteredCampaigns = filterCampaigns({
    campagins: formattedCampaigns,
    currentURL,
  });

  // Execute campaigns
  filteredCampaigns.forEach(campaign => {
    const { timeOnPage, id: campaignId } = campaign;
    const timeoutID = setTimeout(async () => {
      triggerCampaign({ campaignId });
    }, timeOnPage * 1000);
    window.campaignTimers.push(timeoutID);
  });
};
