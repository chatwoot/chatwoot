import { ref } from 'vue';
import { useTrack } from 'dashboard/composables';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import {
  useCopilotDot,
  COPILOT_OPEN_SOURCES,
} from 'dashboard/composables/useCopilotDot';

const uiSettings = ref({});
const updateUISettings = vi.fn(settings => {
  uiSettings.value = { ...uiSettings.value, ...settings };
});

vi.mock('dashboard/composables', () => ({
  useTrack: vi.fn(),
}));

vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({ uiSettings, updateUISettings }),
}));

const enabledFeatures = ref([]);
vi.mock('dashboard/composables/store', () => ({
  useMapGetter: getter =>
    getter === 'getCurrentAccountId'
      ? ref(1)
      : ref((accountId, feature) =>
          enabledFeatures.value.includes(`${accountId}:${feature}`)
        ),
}));

describe('useCopilotDot', () => {
  beforeEach(() => {
    uiSettings.value = { is_copilot_panel_open: false };
    enabledFeatures.value = ['1:copilot_workflows'];
    updateUISettings.mockClear();
    useTrack.mockClear();
  });

  it('shows the dot until the first open, and saves that the person has seen it', () => {
    const { showDot, openCopilot } = useCopilotDot();
    expect(showDot.value).toBe(true);

    openCopilot(COPILOT_OPEN_SOURCES.SIDEBAR_TAB);

    expect(updateUISettings).toHaveBeenCalledWith({
      is_contact_sidebar_open: false,
      is_copilot_panel_open: true,
      copilot_dot_dismissed: true,
    });
    expect(showDot.value).toBe(false);
  });

  it('hides the dot without workflows, and keeps it for when workflows reaches the account', () => {
    enabledFeatures.value = [];
    const { showDot, openCopilot } = useCopilotDot();
    expect(showDot.value).toBe(false);

    openCopilot(COPILOT_OPEN_SOURCES.LAUNCHER);

    expect(updateUISettings).toHaveBeenCalledWith({
      is_contact_sidebar_open: false,
      is_copilot_panel_open: true,
    });
    expect(useTrack).toHaveBeenCalledWith(COPILOT_EVENTS.OPEN, {
      source: 'launcher',
      dot_shown: false,
    });

    enabledFeatures.value = ['1:copilot_workflows'];
    expect(showDot.value).toBe(true);
  });

  it('records where Copilot was opened from and whether the dot was showing', () => {
    const { openCopilot } = useCopilotDot();

    openCopilot(COPILOT_OPEN_SOURCES.LAUNCHER);
    openCopilot(COPILOT_OPEN_SOURCES.REPLY_EDITOR);

    expect(useTrack.mock.calls).toEqual([
      [COPILOT_EVENTS.OPEN, { source: 'launcher', dot_shown: true }],
      [COPILOT_EVENTS.OPEN, { source: 'reply_editor', dot_shown: false }],
    ]);
  });

  it('counts the dot as shown once, even when both buttons show it', () => {
    const { trackDotShown } = useCopilotDot();

    trackDotShown(COPILOT_OPEN_SOURCES.SIDEBAR_TAB);
    trackDotShown(COPILOT_OPEN_SOURCES.LAUNCHER);

    expect(useTrack.mock.calls).toEqual([
      [COPILOT_EVENTS.DOT_SHOWN, { source: 'sidebar_tab' }],
    ]);
  });
});
