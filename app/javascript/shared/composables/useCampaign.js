import { computed } from 'vue';
import { useRoute } from 'dashboard/composables/route';
import { CAMPAIGN_TYPES } from '../constants/campaign';

/**
 * Composable to manage campaign types.
 *
 * @returns {Object} - Computed properties for campaign type and its checks.
 */
export const useCampaign = () => {
  const route = useRoute();

  /**
   * Computed property to determine the current campaign type based on the route name.
   */
  const campaignType = computed(() => {
    const campaignTypeMap = {
      ongoing_campaigns: CAMPAIGN_TYPES.ONGOING,
      one_off: CAMPAIGN_TYPES.ONE_OFF,
      whatsapp: CAMPAIGN_TYPES.WHATSAPP,
    };
    return campaignTypeMap[route.name];
  });

  /**
   * Computed property to check if the current campaign type is 'ongoing'.
   */
  const isOngoingType = computed(() => {
    return campaignType.value === CAMPAIGN_TYPES.ONGOING;
  });
  const isWhatsappType = computed(() => {
    return campaignType.value === CAMPAIGN_TYPES.WHATSAPP;
  });
  /**
   * Computed property to check if the current campaign type is 'one-off'.
   */
  const isOneOffType = computed(() => {
    return campaignType.value === CAMPAIGN_TYPES.ONE_OFF;
  });

  return {
    campaignType,
    isOngoingType,
    isOneOffType,
    isWhatsappType,
  };
};
