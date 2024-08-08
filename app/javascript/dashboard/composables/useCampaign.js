import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { CAMPAIGN_TYPES } from '../constants/campaign';

/**
 * Composable for handling campaign-related computations.
 * @returns {Object} An object containing computed properties for campaign types.
 */
export function useCampaign() {
  const route = useRoute();

  const campaignType = computed(() => {
    const campaignTypeMap = {
      ongoing_campaigns: CAMPAIGN_TYPES.ONGOING,
      one_off: CAMPAIGN_TYPES.ONE_OFF,
    };
    return campaignTypeMap[route.name];
  });

  const isOngoingType = computed(
    () => campaignType.value === CAMPAIGN_TYPES.ONGOING
  );
  const isOneOffType = computed(
    () => campaignType.value === CAMPAIGN_TYPES.ONE_OFF
  );

  return {
    campaignType,
    isOngoingType,
    isOneOffType,
  };
}
