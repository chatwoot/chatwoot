import { triggerCampaign } from 'widget/api/campaign';
const startTimer = async ({ allCampaigns }) => {
  allCampaigns.forEach(campaign => {
    const {
      trigger_rules: { time_on_page: timeOnPage },
      id: campaignId,
    } = campaign;
    setTimeout(async () => {
      await triggerCampaign({ campaignId });
    }, timeOnPage * 1000);
  });
};

export { startTimer };
