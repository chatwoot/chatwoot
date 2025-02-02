import { CAMPAIGN_TYPES } from '../constants/campaign';

export default {
  computed: {
    campaignType() {
      const campaignTypeMap = {
        ongoing_campaigns: CAMPAIGN_TYPES.ONGOING,
        one_off: CAMPAIGN_TYPES.ONE_OFF,
        whatsapp_campaigns: CAMPAIGN_TYPES.WHATSAPP,
      };
      return campaignTypeMap[this.$route.name];
    },
    isOngoingType() {
      return this.campaignType === CAMPAIGN_TYPES.ONGOING;
    },
    isOneOffType() {
      return this.campaignType === CAMPAIGN_TYPES.ONE_OFF;
    },
    isWhatsappType() {
      return this.campaignType === CAMPAIGN_TYPES.WHATSAPP; // Check if it's WhatsApp
    },
  },
};
