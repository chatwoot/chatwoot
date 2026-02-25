import store from '../store';
class CampaignTimer {
  constructor() {
    this.campaignTimers = [];
  }

  initTimers = ({ campaigns }, websiteToken) => {
    this.clearTimers();
    campaigns.forEach(campaign => {
      const { timeOnPage, id: campaignId } = campaign;
      this.campaignTimers[campaignId] = setTimeout(() => {
        store.dispatch('campaign/startCampaign', { campaignId, websiteToken });
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
