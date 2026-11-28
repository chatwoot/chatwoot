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
  const currentAccountId = useMapGetter('getCurrentAccountId');
  const getAccount = useMapGetter('accounts/getAccount');

  // An account with the classic layout keeps the plain empty screen and the corner Copilot button.
  const isClassicLayout = computed(
    () =>
      getAccount.value(currentAccountId.value)?.settings
        ?.copilot_classic_layout === true
  );

  const hasCopilot = computed(
    () =>
      isEnterprise &&
      !shouldShowPaywall(FEATURE_FLAGS.CAPTAIN) &&
      isFeatureFlagEnabled(FEATURE_FLAGS.CAPTAIN) &&
      !isClassicLayout.value
  );

  // Admins can hide the ask bar in Settings > Copilot. Missing means shown. Loading checks this too, so the launcher
  // stays visible when the ask bar is turned off.
  const isShownOnHome = computed(
    () =>
      getAccount.value(currentAccountId.value)?.settings?.copilot
        ?.show_on_home !== false
  );

  // With no inbox, the empty state shows onboarding instead of the ask bar, so the launcher must stay visible.
  const showAskBar = computed(
    () =>
      hasCopilot.value &&
      isShownOnHome.value &&
      assistants.value.length > 0 &&
      inboxes.value.length > 0 &&
      !uiSettings.value.is_copilot_panel_open
  );

  const isAskBarLoading = computed(
    () =>
      hasCopilot.value &&
      isShownOnHome.value &&
      (assistantFlags.value.fetchingList || inboxFlags.value.isFetching)
  );

  return { showAskBar, isAskBarLoading };
}
