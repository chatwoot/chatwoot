import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { shortcutKeys } from 'dashboard/helper/commandbar/shortcuts';
import { isUpgradePageBypassRoute } from 'dashboard/helper/routeHelpers';

const SECTION_GENERAL = 'COMMAND_BAR.SECTIONS.GENERAL';
const SECTION_REPORTS = 'COMMAND_BAR.SECTIONS.REPORTS';
const SECTION_SETTINGS = 'COMMAND_BAR.SECTIONS.SETTINGS';
const SECTION_CREATE = 'COMMAND_BAR.SECTIONS.CREATE';

const SECTION_SCOPES = {
  [SECTION_REPORTS]: ['reports'],
  [SECTION_SETTINGS]: ['settings'],
  [SECTION_CREATE]: ['settings'],
};

const GO_TO_COMMANDS = [
  {
    id: 'goto_my_inbox',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_MY_INBOX',
    section: SECTION_GENERAL,
    icon: 'i-lucide-inbox',
    routeName: 'inbox_view',
  },
  {
    id: 'goto_conversation_dashboard',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONVERSATION_DASHBOARD',
    section: SECTION_GENERAL,
    icon: 'i-lucide-message-circle',
    routeName: 'home',
    shortcut: 'Alt+KeyC',
  },
  {
    id: 'goto_contacts_dashboard',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONTACTS_DASHBOARD',
    section: SECTION_GENERAL,
    icon: 'i-lucide-contact',
    routeName: 'contacts_dashboard_index',
    shortcut: 'Alt+KeyV',
  },
  {
    id: 'goto_captain',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CAPTAIN',
    section: SECTION_GENERAL,
    icon: 'i-lucide-bot',
    routeName: 'captain_assistants_index',
    params: { navigationPath: 'captain_assistants_overview_index' },
  },
  {
    id: 'goto_calls_dashboard',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CALLS_DASHBOARD',
    section: SECTION_GENERAL,
    icon: 'i-lucide-phone',
    routeName: 'calls_dashboard_index',
  },
  {
    id: 'goto_campaigns',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CAMPAIGNS',
    section: SECTION_GENERAL,
    icon: 'i-lucide-megaphone',
    routeName: 'campaigns_livechat_index',
  },
  {
    id: 'goto_help_center',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_HELP_CENTER',
    section: SECTION_GENERAL,
    icon: 'i-lucide-library',
    routeName: 'portals_index',
    params: { navigationPath: 'portals_articles_index' },
  },
  {
    id: 'open_reports_overview',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_REPORTS_OVERVIEW',
    section: SECTION_REPORTS,
    icon: 'i-lucide-chart-column',
    routeName: 'account_overview_reports',
    shortcut: 'Alt+KeyR',
  },
  {
    id: 'open_conversation_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONVERSATION_REPORTS',
    section: SECTION_REPORTS,
    icon: 'i-lucide-message-circle',
    routeName: 'conversation_reports',
  },
  {
    id: 'open_agent_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_AGENT_REPORTS',
    section: SECTION_REPORTS,
    icon: 'i-lucide-square-user',
    routeName: 'agent_reports_index',
  },
  {
    id: 'open_label_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_LABEL_REPORTS',
    section: SECTION_REPORTS,
    icon: 'i-lucide-tags',
    routeName: 'label_reports_index',
  },
  {
    id: 'open_inbox_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_INBOX_REPORTS',
    section: SECTION_REPORTS,
    icon: 'i-lucide-inbox',
    routeName: 'inbox_reports_index',
  },
  {
    id: 'open_team_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_TEAM_REPORTS',
    section: SECTION_REPORTS,
    icon: 'i-lucide-users',
    routeName: 'team_reports_index',
  },
  {
    id: 'open_csat_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CSAT_REPORTS',
    section: SECTION_REPORTS,
    icon: 'i-lucide-smile',
    routeName: 'csat_reports',
  },
  {
    id: 'open_bot_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_BOT_REPORTS',
    section: SECTION_REPORTS,
    icon: 'i-lucide-bot',
    routeName: 'bot_reports',
  },
  {
    id: 'open_sla_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SLA_REPORTS',
    section: SECTION_REPORTS,
    icon: 'i-lucide-clock-alert',
    routeName: 'sla_reports',
  },
  {
    id: 'open_agent_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_AGENTS',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-square-user',
    routeName: 'agent_list',
    shortcut: 'Alt+KeyS',
  },
  {
    id: 'open_team_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_TEAMS',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-users',
    routeName: 'settings_teams_list',
  },
  {
    id: 'open_inbox_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_INBOXES',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-inbox',
    routeName: 'settings_inbox_list',
  },
  {
    id: 'open_template_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_TEMPLATES',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-layout-template',
    routeName: 'settings_templates',
  },
  {
    id: 'open_label_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_LABELS',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-tags',
    routeName: 'labels_list',
  },
  {
    id: 'open_custom_attribute_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_CUSTOM_ATTRIBUTES',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-code',
    routeName: 'attributes_list',
  },
  {
    id: 'open_automation_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_AUTOMATION',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-repeat',
    routeName: 'automation_list',
  },
  {
    id: 'open_agent_bot_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_AGENT_BOTS',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-bot',
    routeName: 'agent_bots',
  },
  {
    id: 'open_macro_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_MACROS',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-toy-brick',
    routeName: 'macros_wrapper',
  },
  {
    id: 'open_canned_response_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_CANNED_RESPONSES',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-message-square-quote',
    routeName: 'canned_list',
  },
  {
    id: 'open_sla_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_SLA',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-clock-alert',
    routeName: 'sla_list',
  },
  {
    id: 'open_conversation_workflow_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_CONVERSATION_WORKFLOW',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-workflow',
    routeName: 'conversation_workflow_index',
  },
  {
    id: 'open_integration_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_INTEGRATIONS',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-blocks',
    routeName: 'settings_applications',
  },
  {
    id: 'open_data_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_DATA',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-database',
    routeName: 'settings_data_imports',
  },
  {
    id: 'open_audit_logs_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_AUDIT_LOGS',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-briefcase',
    routeName: 'auditlogs_list',
  },
  {
    id: 'open_custom_role_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_CUSTOM_ROLES',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-shield-plus',
    routeName: 'custom_roles_list',
  },
  {
    id: 'open_security_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_SECURITY',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-shield',
    routeName: 'security_settings_index',
  },
  {
    id: 'open_billing_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_BILLING',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-credit-card',
    routeName: 'billing_settings_index',
  },
  {
    id: 'open_account_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_ACCOUNT',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-briefcase',
    routeName: 'general_settings_index',
  },
  {
    id: 'open_profile_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_PROFILE',
    section: SECTION_SETTINGS,
    icon: 'i-lucide-user-pen',
    routeName: 'profile_settings_index',
  },
];

const CREATE_COMMANDS = [
  {
    id: 'new_inbox',
    title: 'COMMAND_BAR.COMMANDS.NEW_INBOX',
    section: SECTION_CREATE,
    icon: 'i-lucide-plus',
    routeName: 'settings_inbox_new',
  },
  {
    id: 'new_team',
    title: 'COMMAND_BAR.COMMANDS.NEW_TEAM',
    section: SECTION_CREATE,
    icon: 'i-lucide-plus',
    routeName: 'settings_teams_new',
  },
  {
    id: 'new_macro',
    title: 'COMMAND_BAR.COMMANDS.NEW_MACRO',
    section: SECTION_CREATE,
    icon: 'i-lucide-plus',
    routeName: 'macros_new',
  },
  {
    id: 'new_campaign',
    title: 'COMMAND_BAR.COMMANDS.NEW_CAMPAIGN',
    section: SECTION_CREATE,
    icon: 'i-lucide-plus',
    routeName: 'campaigns_whatsapp_new',
  },
];

const TARGET_PAGES = [
  {
    id: 'goto_inbox',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_INBOX',
    icon: 'i-lucide-inbox',
    routeName: 'inbox_dashboard',
    getter: 'inboxes/getInboxes',
    target: inbox => ({
      id: `inbox-${inbox.id}`,
      title: inbox.name,
      icon: getInboxIconByType(inbox.channel_type, inbox.medium, 'line'),
      params: { inbox_id: inbox.id },
    }),
  },
  {
    id: 'goto_team',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_TEAM',
    icon: 'i-lucide-users',
    routeName: 'team_conversations',
    getter: 'teams/getTeams',
    target: team => ({
      id: `team-${team.id}`,
      title: team.name,
      icon: 'i-lucide-users',
      params: { teamId: team.id },
    }),
  },
  {
    id: 'goto_label',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_LABEL',
    icon: 'i-lucide-tag',
    routeName: 'label_conversations',
    getter: 'labels/getLabels',
    target: label => ({
      id: `label-${label.title}`,
      title: label.title,
      icon: 'i-lucide-tag',
      prefix: '#',
      params: { label: label.title },
    }),
  },
];

export function useGoToCommands(isPaywalled = ref(false)) {
  const { t } = useI18n();
  const router = useRouter();
  const { checkPermissions, checkInstallationType, isFeatureFlagEnabled } =
    usePolicy();

  const currentAccountId = useMapGetter('getCurrentAccountId');
  const targetLists = Object.fromEntries(
    TARGET_PAGES.map(page => [page.id, useMapGetter(page.getter)])
  );

  const resolveRoute = ({ routeName, params }) =>
    router.resolve({
      name: routeName,
      params: { accountId: currentAccountId.value, ...params },
    });

  const isAvailable = route => {
    const { meta } = route;

    if (!isFeatureFlagEnabled(meta?.featureFlag)) return false;
    if (!checkPermissions(meta?.permissions)) return false;
    if (!checkInstallationType(meta?.installationTypes)) return false;

    return !isPaywalled.value || isUpgradePageBypassRoute(route.name);
  };

  const pageCommands = computed(() =>
    [...GO_TO_COMMANDS, ...CREATE_COMMANDS].flatMap(command => {
      const route = resolveRoute(command);
      if (!isAvailable(route)) return [];

      const section = t(command.section);
      return {
        id: command.id,
        section,
        title: t(command.title),
        keywords: [section],
        icon: command.icon,
        scopes: SECTION_SCOPES[command.section],
        shortcut: command.shortcut && shortcutKeys(command.shortcut),
        run: () => router.push(route),
      };
    })
  );

  const targetCommands = computed(() =>
    TARGET_PAGES.flatMap(page => {
      const targets = targetLists[page.id].value.map(page.target);
      if (!targets.length) return [];
      if (!isAvailable(resolveRoute({ ...page, params: targets[0].params })))
        return [];

      const section = t(SECTION_GENERAL);
      return [
        {
          id: page.id,
          title: t(page.title),
          section,
          icon: page.icon,
          page: true,
        },
        ...targets.map(({ params, ...target }) => ({
          ...target,
          parent: page.id,
          section,
          run: () =>
            router.push(resolveRoute({ routeName: page.routeName, params })),
        })),
      ];
    })
  );

  const goToCommands = computed(() => [
    ...pageCommands.value,
    ...targetCommands.value,
  ]);

  return { goToCommands };
}
