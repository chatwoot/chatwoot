import { CAMPAIGN_TYPES } from '../constants/campaign';
import inboxMixin from './inboxMixin';
export default {
  mixins: [inboxMixin],
  computed: {
    campaignType() {
      if (this.isAWebWidgetInbox) {
        return CAMPAIGN_TYPES.ONGOING;
      }
      return CAMPAIGN_TYPES.ONE_OFF;
    },
    isOngoingType() {
      return this.campaignType === CAMPAIGN_TYPES.ONGOING;
    },
    isOnOffType() {
      return this.campaignType === CAMPAIGN_TYPES.ONE_OFF;
    },
  },
};
