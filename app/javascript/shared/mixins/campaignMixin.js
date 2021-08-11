import { CAMPAIGN_TYPES } from '../constants/campaign';
export default {
  computed: {
    campaignType() {
      const pageURL = window.location.href;
      const type = pageURL.substr(pageURL.lastIndexOf('/') + 1);
      return type;
    },
    isOngoingType() {
      return this.campaignType === CAMPAIGN_TYPES.ONGOING;
    },
    isOnOffType() {
      return this.campaignType === CAMPAIGN_TYPES.ONE_OFF;
    },
  },
};
