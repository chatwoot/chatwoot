import { computed } from 'vue';
import { useTrack } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';

export const COPILOT_OPEN_SOURCES = Object.freeze({
  LAUNCHER: 'launcher',
  SIDEBAR_TAB: 'sidebar_tab',
  REPLY_EDITOR: 'reply_editor',
  EMPTY_STATE: 'empty_state',
});

// The floating button and the sidebar tab both show the dot, so it counts as shown once per page load.
let isDotShownTracked = false;

/**
 * The dot on the Copilot buttons points people to Copilot until they first open it. That is saved in
 * their UI settings, so the dot doesn't come back on another device.
 */
export function useCopilotDot() {
  const { uiSettings, updateUISettings } = useUISettings();
  const showDot = computed(() => !uiSettings.value.copilot_dot_dismissed);

  const trackDotShown = source => {
    if (isDotShownTracked) return;

    isDotShownTracked = true;
    useTrack(COPILOT_EVENTS.DOT_SHOWN, { source });
  };

  const openCopilot = source => {
    useTrack(COPILOT_EVENTS.OPEN, { source, dot_shown: showDot.value });
    updateUISettings({
      is_contact_sidebar_open: false,
      is_copilot_panel_open: true,
      ...(showDot.value && { copilot_dot_dismissed: true }),
    });
  };

  return { showDot, trackDotShown, openCopilot };
}
