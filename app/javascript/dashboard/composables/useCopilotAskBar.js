import { useMapGetter } from 'dashboard/composables/store';
import { useConfig } from 'dashboard/composables/useConfig';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { computed } from 'vue';

export function useCopilotAskBar() {
  const { isEnterprise } = useConfig();
  const { uiSettings } = useUISettings();
  const { isFeatureFlagEnabled, shouldShowPaywall } = usePolicy();
  const assistants = useMapGetter('captainAssistants/getRecords');
  const assistantFlags = useMapGetter('captainAssistants/getUIFlags');
  const inboxes = useMapGetter('inboxes/getInboxes');
  const inboxFlags = useMapGetter('inboxes/getUIFlags');

  const hasCopilot = computed(
    () =>
      isEnterprise &&
      !shouldShowPaywall(FEATURE_FLAGS.CAPTAIN) &&
      isFeatureFlagEnabled(FEATURE_FLAGS.CAPTAIN)
  );

  // With no inbox, the empty state shows onboarding instead of the ask bar, so the launcher must stay visible.
  const showAskBar = computed(
    () =>
      hasCopilot.value &&
      assistants.value.length > 0 &&
      inboxes.value.length > 0 &&
      !uiSettings.value.is_copilot_panel_open
  );

  const isAskBarLoading = computed(
    () =>
      hasCopilot.value &&
      (assistantFlags.value.fetchingList || inboxFlags.value.isFetching)
  );

  return { showAskBar, isAskBarLoading };
}
