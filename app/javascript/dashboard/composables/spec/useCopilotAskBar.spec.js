import { ref } from 'vue';
import { useCopilotAskBar } from '../useCopilotAskBar';

const testState = vi.hoisted(() => ({
  isEnterprise: true,
  showPaywall: false,
  enabledFlags: [],
}));
const assistants = ref([]);
const assistantFlags = ref({});
const uiSettings = ref({});

vi.mock('dashboard/composables/useConfig', () => ({
  useConfig: () => ({ isEnterprise: testState.isEnterprise }),
}));
vi.mock('dashboard/composables/usePolicy', () => ({
  usePolicy: () => ({
    isFeatureFlagEnabled: flag => testState.enabledFlags.includes(flag),
    shouldShowPaywall: () => testState.showPaywall,
  }),
}));
vi.mock('dashboard/composables/useUISettings', () => ({
  useUISettings: () => ({ uiSettings }),
}));
vi.mock('dashboard/composables/store', () => ({
  useMapGetter: key =>
    key === 'captainAssistants/getUIFlags' ? assistantFlags : assistants,
}));

describe('useCopilotAskBar', () => {
  beforeEach(() => {
    testState.isEnterprise = true;
    testState.showPaywall = false;
    testState.enabledFlags = ['captain_integration', 'copilot_workflows'];
    assistants.value = [{ id: 7 }];
    assistantFlags.value = { fetchingList: false };
    uiSettings.value = {};
  });

  it('shows the ask bar when Copilot can answer', () => {
    expect(useCopilotAskBar().showAskBar.value).toBe(true);
  });

  it('hides the ask bar on the Community edition', () => {
    testState.isEnterprise = false;

    expect(useCopilotAskBar().showAskBar.value).toBe(false);
  });

  it('hides the ask bar when the plan does not include Captain', () => {
    testState.showPaywall = true;

    expect(useCopilotAskBar().showAskBar.value).toBe(false);
  });

  it('hides the ask bar when Captain is turned off for the account', () => {
    testState.enabledFlags = ['copilot_workflows'];

    expect(useCopilotAskBar().showAskBar.value).toBe(false);
  });

  it('hides the ask bar for the older Copilot', () => {
    testState.enabledFlags = ['captain_integration'];

    expect(useCopilotAskBar().showAskBar.value).toBe(false);
  });

  it('hides the ask bar when no assistant exists to answer', () => {
    assistants.value = [];

    expect(useCopilotAskBar().showAskBar.value).toBe(false);
  });

  it('counts the ask bar as loading until the assistants arrive', () => {
    assistants.value = [];
    assistantFlags.value = { fetchingList: true };

    const { showAskBar, isAskBarLoading } = useCopilotAskBar();

    expect(showAskBar.value).toBe(false);
    expect(isAskBarLoading.value).toBe(true);
  });

  it('hides the ask bar while the Copilot panel is open', () => {
    uiSettings.value = { is_copilot_panel_open: true };

    expect(useCopilotAskBar().showAskBar.value).toBe(false);
  });
});
