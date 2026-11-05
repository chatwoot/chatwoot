import { useMapGetter, useStore } from 'dashboard/composables/store';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useGoToCommandHotKeys } from '../useGoToCommandHotKeys';
import { MOCK_FEATURE_FLAGS } from './fixtures';

vi.mock('dashboard/composables/store');
vi.mock('vue-i18n');
vi.mock('vue-router');
vi.mock('dashboard/composables/usePolicy');

const ROUTE_META = {
  calls_dashboard_index: {
    permissions: ['administrator', 'agent'],
    installationTypes: ['cloud', 'enterprise'],
  },
  portals_index: {
    featureFlag: MOCK_FEATURE_FLAGS.HELP_CENTER,
    permissions: ['administrator', 'knowledge_base_manage'],
  },
  agent_reports_index: {
    featureFlag: MOCK_FEATURE_FLAGS.REPORTS,
    permissions: ['administrator', 'report_manage'],
  },
  contacts_dashboard_index: {
    featureFlag: MOCK_FEATURE_FLAGS.CRM,
    permissions: ['administrator', 'agent', 'contact_manage'],
  },
  agent_list: {
    featureFlag: MOCK_FEATURE_FLAGS.AGENT_MANAGEMENT,
    permissions: ['administrator'],
  },
  settings_teams_list: {
    featureFlag: MOCK_FEATURE_FLAGS.TEAM_MANAGEMENT,
    permissions: ['administrator'],
  },
  settings_inbox_list: {
    featureFlag: MOCK_FEATURE_FLAGS.INBOX_MANAGEMENT,
    permissions: ['administrator'],
  },
  labels_list: {
    featureFlag: MOCK_FEATURE_FLAGS.LABELS,
    permissions: ['administrator'],
  },
  canned_list: {
    featureFlag: MOCK_FEATURE_FLAGS.CANNED_RESPONSES,
    permissions: ['administrator', 'agent', 'conversation_manage'],
  },
  macros_wrapper: {
    featureFlag: MOCK_FEATURE_FLAGS.MACROS,
    permissions: ['administrator', 'agent', 'conversation_manage'],
  },
  settings_applications: {
    featureFlag: MOCK_FEATURE_FLAGS.INTEGRATIONS,
    permissions: ['administrator'],
  },
  automation_list: {
    featureFlag: MOCK_FEATURE_FLAGS.AUTOMATIONS,
    permissions: ['administrator'],
  },
  auditlogs_list: {
    featureFlag: MOCK_FEATURE_FLAGS.AUDIT_LOGS,
    permissions: ['administrator'],
  },
  general_settings_index: { permissions: ['administrator'] },
  billing_settings_index: { permissions: ['administrator'] },
  account_overview_reports: {
    featureFlag: MOCK_FEATURE_FLAGS.REPORTS,
    permissions: ['administrator', 'report_manage'],
  },
  profile_settings_index: {
    permissions: ['administrator', 'agent', 'custom_role'],
  },
};

const DEFAULT_META = { permissions: ['administrator', 'agent'] };

describe('useGoToCommandHotKeys', () => {
  let store;
  let userPermissions;
  let installationType;
  let disabledFeatures;

  beforeEach(() => {
    userPermissions = ['administrator'];
    installationType = 'cloud';
    disabledFeatures = [];
    store = {
      getters: {
        getCurrentAccountId: 1,
      },
    };

    useStore.mockReturnValue(store);
    useMapGetter.mockImplementation(key => ({
      value: store.getters[key],
    }));

    useI18n.mockReturnValue({ t: vi.fn(key => key) });
    useRouter.mockReturnValue({
      push: vi.fn(),
      resolve: vi.fn(({ name, params }) => ({
        name,
        params,
        meta: ROUTE_META[name] || DEFAULT_META,
      })),
    });
    usePolicy.mockReturnValue({
      isFeatureFlagEnabled: vi.fn(
        flag => !flag || !disabledFeatures.includes(flag)
      ),
      checkPermissions: vi.fn((required = []) =>
        required.some(permission => userPermissions.includes(permission))
      ),
      checkInstallationType: vi.fn(
        (types = []) => !types.length || types.includes(installationType)
      ),
    });
  });

  it('should return goToCommandHotKeys computed property', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    expect(goToCommandHotKeys.value).toBeDefined();
    expect(goToCommandHotKeys.value.length).toBeGreaterThan(0);
  });

  it('should filter commands based on feature flags', () => {
    disabledFeatures = [MOCK_FEATURE_FLAGS.CRM];
    const { goToCommandHotKeys } = useGoToCommandHotKeys();

    const ids = goToCommandHotKeys.value.map(cmd => cmd.id);
    expect(ids).not.toContain('goto_contacts_dashboard');
    expect(ids).toContain('open_account_settings');
  });

  it('should filter commands for non-admin users', () => {
    userPermissions = ['agent'];
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

  it('should include commands granted by a custom role permission', () => {
    userPermissions = ['custom_role', 'report_manage'];
    const { goToCommandHotKeys } = useGoToCommandHotKeys();

    expect(
      goToCommandHotKeys.value.find(cmd => cmd.id.includes('reports_overview'))
    ).toBeDefined();
    expect(
      goToCommandHotKeys.value.find(cmd => cmd.id.includes('agent_settings'))
    ).toBeUndefined();
  });

  it('should hide the help center from agents, who cannot open it', () => {
    userPermissions = ['agent'];
    const { goToCommandHotKeys } = useGoToCommandHotKeys();

    expect(goToCommandHotKeys.value.map(cmd => cmd.id)).not.toContain(
      'goto_help_center'
    );
  });

  it('should offer the help center to a knowledge base manager', () => {
    userPermissions = ['custom_role', 'knowledge_base_manage'];
    const { goToCommandHotKeys } = useGoToCommandHotKeys();

    expect(goToCommandHotKeys.value.map(cmd => cmd.id)).toContain(
      'goto_help_center'
    );
  });

  it('should drop report commands when the reports feature is disabled', () => {
    disabledFeatures = [MOCK_FEATURE_FLAGS.REPORTS];
    const { goToCommandHotKeys } = useGoToCommandHotKeys();

    const ids = goToCommandHotKeys.value.map(cmd => cmd.id);
    expect(ids).not.toContain('open_reports_overview');
    expect(ids).not.toContain('open_agent_reports');
  });

  it('should drop commands whose route is not available on the installation', () => {
    installationType = 'community';
    const { goToCommandHotKeys } = useGoToCommandHotKeys();

    expect(
      goToCommandHotKeys.value.find(cmd => cmd.id === 'goto_calls_dashboard')
    ).toBeUndefined();
  });

  it('should only keep routes that bypass the upgrade page when paywalled', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys(ref(true));

    expect(goToCommandHotKeys.value.map(cmd => cmd.id).sort()).toEqual([
      'open_account_settings',
      'open_agent_settings',
      'open_billing_settings',
      'open_inbox_settings',
    ]);
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

  it('should push the resolved route when handler is called', () => {
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    goToCommandHotKeys.value.forEach(command => {
      command.handler();
      expect(useRouter().push).toHaveBeenCalledWith(
        expect.objectContaining({ name: expect.any(String) })
      );
    });
  });

  it('should resolve every route against the current account', () => {
    store.getters.getCurrentAccountId = 42;
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    goToCommandHotKeys.value.forEach(command => {
      command.handler();
      expect(useRouter().push).toHaveBeenCalledWith(
        expect.objectContaining({
          params: expect.objectContaining({ accountId: 42 }),
        })
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
    const ids = goToCommandHotKeys.value.map(cmd => cmd.id);
    expect(ids).toContain('goto_contacts_dashboard');
    expect(ids).toContain('open_automation_settings');
  });

  it('should not return commands for disabled features', () => {
    disabledFeatures = Object.values(MOCK_FEATURE_FLAGS);
    const { goToCommandHotKeys } = useGoToCommandHotKeys();
    const ids = goToCommandHotKeys.value.map(cmd => cmd.id);
    expect(ids).not.toContain('goto_contacts_dashboard');
    expect(ids).not.toContain('open_automation_settings');
    expect(ids).not.toContain('open_audit_logs_settings');
  });

  it('should not offer settings the custom role cannot open', () => {
    userPermissions = ['custom_role', 'conversation_manage'];
    const { goToCommandHotKeys } = useGoToCommandHotKeys();

    const ids = goToCommandHotKeys.value.map(cmd => cmd.id);
    expect(ids).not.toContain('open_automation_settings');
    expect(ids).not.toContain('open_audit_logs_settings');
    expect(ids).toContain('open_canned_response_settings');
  });
});
