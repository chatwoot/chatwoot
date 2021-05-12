import { triggerCampaign } from 'widget/api/campaign';
window.campaignTimers = [];

const stripTrailingSlash = ({ URL }) => {
  return URL.replace(/\/$/, '');
};

const startCampaigns = async ({ allCampaigns, currentURL }) => {
  // Clear all campaign timers
  window.campaignTimers.forEach(timerId => {
    clearTimeout(timerId);
  });
  // Find all campaigns that matches the current URL
  const filteredCampaigns = allCampaigns
    .map(item => {
      return {
        ...item,
        timeOnpage: item?.trigger_rules?.time_on_page,
        url: item?.trigger_rules?.url,
      };
    })
    .filter(item => {
      return (
        stripTrailingSlash({ URL: item.url }) ===
        stripTrailingSlash({ URL: currentURL })
      );
    });
  // Execute campaigns
  filteredCampaigns.forEach(campaign => {
    const {
      trigger_rules: { time_on_page: timeOnPage },
      id: campaignId,
    } = campaign;
    const timeoutID = setTimeout(async () => {
      await triggerCampaign({ campaignId });
    }, timeOnPage * 1000);
    window.campaignTimers.push(timeoutID);
  });
};

export { startCampaigns };
