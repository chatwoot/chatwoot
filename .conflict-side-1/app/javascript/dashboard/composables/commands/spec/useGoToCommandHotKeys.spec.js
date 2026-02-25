import { useGoToCommandHotKeys } from '../useGoToCommandHotKeys';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { MOCK_FEATURE_FLAGS } from './fixtures';

vi.mock('dashboard/composables/store');
vi.mock('vue-i18n');
vi.mock('vue-router');
vi.mock('dashboard/composables/useAdmin');
vi.mock('dashboard/helper/URLHelper');

const mockRoutes = [
  { path: 'accounts/:accountId/dashboard', name: 'dashboard' },
  {
    path: 'accounts/:accountId/contacts',
    name: 'contacts',
    featureFlag: MOCK_FEATURE_FLAGS.CRM,
  },
  {
    path: 'accounts/:accountId/settings/agents/list',
    name: 'agent_settings',
    featureFlag: MOCK_FEATURE_FLAGS.AGENT_MANAGEMENT,
  },
  {
    path: 'accounts/:accountId/settings/teams/list',
    name: 'team_settings',
    featureFlag: MOCK_FEATURE_FLAGS.TEAM_MANAGEMENT,
  },
  {
    path: 'accounts/:accountId/settings/inboxes/list',
    name: 'inbox_settings',
    featureFlag: MOCK_FEATURE_FLAGS.INBOX_MANAGEMENT,
  },
  { path: 'accounts/:accountId/profile/settings', name: 'profile_settings' },
  { path: 'accounts/:accountId/notifications', name: 'notifications' },
  {
    path: 'accounts/:accountId/reports/overview',
    name: 'reports_overview',
    featureFlag: MOCK_FEATURE_FLAGS.REPORTS,
  },
  {
    path: 'accounts/:accountId/settings/labels/list',
    name: 'label_settings',
    featureFlag: MOCK_FEATURE_FLAGS.LABELS,
  },
  {
    path: 'accounts/:accountId/settings/canned-response/list',
    name: 'canned_responses',
    featureFlag: MOCK_FEATURE_FLAGS.CANNED_RESPONSES,
  },
  {
    path: 'accounts/:accountId/settings/applications',
    name: 'applications',
    featureFlag: MOCK_FEATURE_FLAGS.INTEGRATIONS,
  },
];

describe('useGoToCommandHotKeys', () => {
  let store;

  beforeEach(() => {
    store = {
      getters: {
        getCurrentAccountId: 1,
        'accounts/isFeatureEnabledonAccount': vi.fn().mockReturnValue(true),
      },
    };

    useStore.mockReturnValue(store);
    useMapGetter.mockImplementation(key => ({
      value: store.getters[key],
    }));

    useI18n.mockReturnValue({ t: vi.fn(key => key) });
    useRouter.mockReturnValue({ push: vi.fn() });
    useAdmin.mockReturnValue({ isAdmin: { value: true } });
    frontendURL.mockImplementation(url => url);
  });

  it('should return goToCommandHotKeys computed property', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    expect(goToCommandHotKeys.value).toBeDefined();
    expect(goToCommandHotKeys.value.length).toBeGreaterThan(0);
  });

  it('should filter commands based on feature flags', () => {
    store.getters['accounts/isFeatureEnabledonAccount'] = vi.fn(
      (accountId, flag) => flag !== MOCK_FEATURE_FLAGS.CRM
    );
    const { goToCommandHotKeys } = useGoToCommandHotKeys();

    mockRoutes.forEach(route => {
      const command = goToCommandHotKeys.value.find(cmd =>
        cmd.id.includes(route.name)
      );
      if (route.featureFlag === MOCK_FEATURE_FLAGS.CRM) {
        expect(command).toBeUndefined();
      } else if (!route.featureFlag) {
        expect(command).toBeDefined();
      }
    });
  });

  it('should filter commands for non-admin users', () => {
    useAdmin.mockReturnValue({ isAdmin: { value: false } });
    const { goToCommandHotKeys } = useGoToCommandHotKeys();

    const adminOnlyCommands = goToCommandHotKeys.value.filter(
      cmd =>
        cmd.id.includes('agent_settings') ||
        cmd.id.includes('team_settings') ||
        cmd.id.includes('inbox_settings')
    );
    expect(adminOnlyCommands.length).toBe(0);
  });

  it('should include commands for both admin and agent roles when user is admin', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    const adminCommand = goToCommandHotKeys.value.find(cmd =>
      cmd.id.includes('agent_settings')
    );
    const agentCommand = goToCommandHotKeys.value.find(cmd =>
      cmd.id.includes('profile_settings')
    );
    expect(adminCommand).toBeDefined();
    expect(agentCommand).toBeDefined();
  });

  it('should translate section and title for each command', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    goToCommandHotKeys.value.forEach(command => {
      expect(useI18n().t).toHaveBeenCalledWith(
        expect.stringContaining('COMMAND_BAR.SECTIONS.')
      );
      expect(useI18n().t).toHaveBeenCalledWith(
        expect.stringContaining('COMMAND_BAR.COMMANDS.')
      );
      expect(command.section).toBeDefined();
      expect(command.title).toBeDefined();
    });
  });

  it('should call router.push with correct URL when handler is called', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    goToCommandHotKeys.value.forEach(command => {
      command.handler();
      expect(useRouter().push).toHaveBeenCalledWith(expect.any(String));
    });
  });

  it('should use current account ID in the path', () => {
    store.getters.getCurrentAccountId = 42;
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    goToCommandHotKeys.value.forEach(command => {
      command.handler();
      expect(useRouter().push).toHaveBeenCalledWith(
        expect.stringContaining('42')
      );
    });
  });

  it('should include icon for each command', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    goToCommandHotKeys.value.forEach(command => {
      expect(command.icon).toBeDefined();
    });
  });

  it('should return commands for all enabled features', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    const enabledFeatureCommands = goToCommandHotKeys.value.filter(cmd =>
      mockRoutes.some(route => route.featureFlag && cmd.id.includes(route.name))
    );
    expect(enabledFeatureCommands.length).toBeGreaterThan(0);
  });

  it('should not return commands for disabled features', () => {
    store.getters['accounts/isFeatureEnabledonAccount'] = vi.fn(() => false);
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    const disabledFeatureCommands = goToCommandHotKeys.value.filter(cmd =>
      mockRoutes.some(route => route.featureFlag && cmd.id.includes(route.name))
    );
    expect(disabledFeatureCommands.length).toBe(0);
  });
});
