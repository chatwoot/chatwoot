import store from '../store';
class CampaignTimer {
  constructor(app) {
    this.app = app;
    this.campaignTimers = [];
  }

  initTimers = ({ campaigns }) => {
    this.clearTimers();
    campaigns.forEach(campaign => {
      const { timeOnPage, id: campaignId } = campaign;
      this.campaignTimers[campaignId] = setTimeout(() => {
        // this.app.$store.dispatch('campaign/startCampaign',{campaignId});
        store.dispatch('campaign/startCampaign', { campaignId });
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

// export default {
//   init() {
//     const campaign = new CampaignTimer(window.WOOT_WIDGET);
//     return campaign;
//   },
// };
export default new CampaignTimer(window.WOOT_WIDGET);
