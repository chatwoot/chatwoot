import { triggerCampaign } from 'widget/api/campaign';

class CampaignTimer {
  constructor(allCampaigns) {
    this.campaignTimers = [];
    this.allCampaigns = allCampaigns;
  }

  initTimer = () => {
    this.clearTimers();
    this.allCampaigns.forEach(campaign => {
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

export default {
  init({ allCampaigns }) {
    const campaignTimer = new CampaignTimer(allCampaigns);
    return campaignTimer;
  },
};
