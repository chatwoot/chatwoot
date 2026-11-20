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

  const hasWorkflows = computed(
    () =>
      isEnterprise &&
      !shouldShowPaywall(FEATURE_FLAGS.CAPTAIN) &&
      isFeatureFlagEnabled(FEATURE_FLAGS.CAPTAIN) &&
      isFeatureFlagEnabled(FEATURE_FLAGS.COPILOT_WORKFLOWS)
  );

  const showAskBar = computed(
    () =>
      hasWorkflows.value &&
      assistants.value.length > 0 &&
      !uiSettings.value.is_copilot_panel_open
  );

  const isAskBarLoading = computed(
    () => hasWorkflows.value && assistantFlags.value.fetchingList
  );

  return { showAskBar, isAskBarLoading };
}
