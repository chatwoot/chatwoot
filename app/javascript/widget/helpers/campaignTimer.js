import { triggerCampaign } from 'widget/api/campaign';

class CampaignTimer {
  constructor() {
    this.campaignTimers = [];
  }

  initTimers = ({ campaigns }) => {
    this.clearTimers();
    campaigns.forEach(campaign => {
      const { timeOnPage, id: campaignId } = campaign;
      this.campaignTimers[campaignId] = setTimeout(() => {
        triggerCampaign({ campaignId });
      }, timeOnPage * 1000);
    });
  };

  clearTimers = () => {
    this.campaignTimers.forEach(timerId => {
      clearTimeout(timerId);
      this.campaignTimers[timerId] = null;
    });
  };
}
export default new CampaignTimer();
