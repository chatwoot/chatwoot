import { ref } from 'vue';
import { useCopilotAskBar } from '../useCopilotAskBar';

const testState = vi.hoisted(() => ({
  isEnterprise: true,
  showPaywall: false,
  enabledFlags: [],
}));
const assistants = ref([]);
const assistantFlags = ref({});
const inboxes = ref([]);
const inboxFlags = ref({});
const uiSettings = ref({});
const accountSettings = ref({});

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
    ({
      'captainAssistants/getRecords': assistants,
      'captainAssistants/getUIFlags': assistantFlags,
      'inboxes/getInboxes': inboxes,
      'inboxes/getUIFlags': inboxFlags,
      getCurrentAccountId: ref(1),
      'accounts/getAccount': ref(() => ({ settings: accountSettings.value })),
    })[key],
}));

describe('useCopilotAskBar', () => {
  beforeEach(() => {
    testState.isEnterprise = true;
    testState.showPaywall = false;
    testState.enabledFlags = ['captain_integration'];
    assistants.value = [{ id: 7 }];
    assistantFlags.value = { fetchingList: false };
    inboxes.value = [{ id: 1 }];
    inboxFlags.value = { isFetching: false };
    uiSettings.value = {};
    accountSettings.value = {};
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
    testState.enabledFlags = [];

    expect(useCopilotAskBar().showAskBar.value).toBe(false);
  });

  it('hides the ask bar for an account on the classic layout, so the launcher stays', () => {
    accountSettings.value = { copilot_classic_layout: true };
    assistantFlags.value = { fetchingList: true };

    const { showAskBar, isAskBarLoading } = useCopilotAskBar();

    expect(showAskBar.value).toBe(false);
    expect(isAskBarLoading.value).toBe(false);
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

  it('hides the ask bar when the user has no inbox, so the launcher stays', () => {
    inboxes.value = [];

    expect(useCopilotAskBar().showAskBar.value).toBe(false);
  });

  it('counts the ask bar as loading until the inboxes arrive', () => {
    inboxes.value = [];
    inboxFlags.value = { isFetching: true };

    expect(useCopilotAskBar().isAskBarLoading.value).toBe(true);
  });

  it('hides the ask bar while the Copilot panel is open', () => {
    uiSettings.value = { is_copilot_panel_open: true };

    expect(useCopilotAskBar().showAskBar.value).toBe(false);
  });
});
