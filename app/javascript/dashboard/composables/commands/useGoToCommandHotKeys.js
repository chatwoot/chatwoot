import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMapGetter } from 'dashboard/composables/store';
import { useRouter } from 'vue-router';
import { usePolicy } from 'dashboard/composables/usePolicy';
import {
  ICON_BLOCKS,
  ICON_BOT,
  ICON_BRIEFCASE,
  ICON_CHART,
  ICON_CLOCK_ALERT,
  ICON_CODE,
  ICON_CONTACT,
  ICON_CREDIT_CARD,
  ICON_DATABASE,
  ICON_INBOX,
  ICON_LAYOUT_TEMPLATE,
  ICON_LIBRARY,
  ICON_MEGAPHONE,
  ICON_MESSAGE_CIRCLE,
  ICON_MESSAGE_QUOTE,
  ICON_PHONE,
  ICON_REPEAT,
  ICON_SMILE,
  ICON_SQUARE_USER,
  ICON_TAGS,
  ICON_TOY_BRICK,
  ICON_USERS,
  ICON_USER_PEN,
} from 'dashboard/helper/commandbar/icons';
import { isUpgradePageBypassRoute } from 'dashboard/helper/routeHelpers';

const SECTION_GENERAL = 'COMMAND_BAR.SECTIONS.GENERAL';
const SECTION_REPORTS = 'COMMAND_BAR.SECTIONS.REPORTS';
const SECTION_SETTINGS = 'COMMAND_BAR.SECTIONS.SETTINGS';

const GO_TO_COMMANDS = [
  {
    id: 'goto_my_inbox',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_MY_INBOX',
    section: SECTION_GENERAL,
    icon: ICON_INBOX,
    routeName: 'inbox_view',
  },
  {
    id: 'goto_conversation_dashboard',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONVERSATION_DASHBOARD',
    section: SECTION_GENERAL,
    icon: ICON_MESSAGE_CIRCLE,
    routeName: 'home',
  },
  {
    id: 'goto_contacts_dashboard',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONTACTS_DASHBOARD',
    section: SECTION_GENERAL,
    icon: ICON_CONTACT,
    routeName: 'contacts_dashboard_index',
  },
  {
    id: 'goto_captain',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CAPTAIN',
    section: SECTION_GENERAL,
    icon: ICON_BOT,
    routeName: 'captain_assistants_index',
    params: { navigationPath: 'captain_assistants_overview_index' },
  },
  {
    id: 'goto_calls_dashboard',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CALLS_DASHBOARD',
    section: SECTION_GENERAL,
    icon: ICON_PHONE,
    routeName: 'calls_dashboard_index',
  },
  {
    id: 'goto_campaigns',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CAMPAIGNS',
    section: SECTION_GENERAL,
    icon: ICON_MEGAPHONE,
    routeName: 'campaigns_livechat_index',
  },
  {
    id: 'goto_help_center',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_HELP_CENTER',
    section: SECTION_GENERAL,
    icon: ICON_LIBRARY,
    routeName: 'portals_index',
    params: { navigationPath: 'portals_articles_index' },
  },
  {
    id: 'open_reports_overview',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_REPORTS_OVERVIEW',
    section: SECTION_REPORTS,
    icon: ICON_CHART,
    routeName: 'account_overview_reports',
  },
  {
    id: 'open_conversation_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONVERSATION_REPORTS',
    section: SECTION_REPORTS,
    icon: ICON_MESSAGE_CIRCLE,
    routeName: 'conversation_reports',
  },
  {
    id: 'open_agent_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_AGENT_REPORTS',
    section: SECTION_REPORTS,
    icon: ICON_SQUARE_USER,
    routeName: 'agent_reports_index',
  },
  {
    id: 'open_label_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_LABEL_REPORTS',
    section: SECTION_REPORTS,
    icon: ICON_TAGS,
    routeName: 'label_reports_index',
  },
  {
    id: 'open_inbox_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_INBOX_REPORTS',
    section: SECTION_REPORTS,
    icon: ICON_INBOX,
    routeName: 'inbox_reports_index',
  },
  {
    id: 'open_team_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_TEAM_REPORTS',
    section: SECTION_REPORTS,
    icon: ICON_USERS,
    routeName: 'team_reports_index',
  },
  {
    id: 'open_csat_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CSAT_REPORTS',
    section: SECTION_REPORTS,
    icon: ICON_SMILE,
    routeName: 'csat_reports',
  },
  {
    id: 'open_bot_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_BOT_REPORTS',
    section: SECTION_REPORTS,
    icon: ICON_BOT,
    routeName: 'bot_reports',
  },
  {
    id: 'open_sla_reports',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SLA_REPORTS',
    section: SECTION_REPORTS,
    icon: ICON_CLOCK_ALERT,
    routeName: 'sla_reports',
  },
  {
    id: 'open_agent_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_AGENTS',
    section: SECTION_SETTINGS,
    icon: ICON_SQUARE_USER,
    routeName: 'agent_list',
  },
  {
    id: 'open_team_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_TEAMS',
    section: SECTION_SETTINGS,
    icon: ICON_USERS,
    routeName: 'settings_teams_list',
  },
  {
    id: 'open_inbox_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_INBOXES',
    section: SECTION_SETTINGS,
    icon: ICON_INBOX,
    routeName: 'settings_inbox_list',
  },
  {
    id: 'open_template_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_TEMPLATES',
    section: SECTION_SETTINGS,
    icon: ICON_LAYOUT_TEMPLATE,
    routeName: 'settings_templates',
  },
  {
    id: 'open_label_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_LABELS',
    section: SECTION_SETTINGS,
    icon: ICON_TAGS,
    routeName: 'labels_list',
  },
  {
    id: 'open_custom_attribute_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_CUSTOM_ATTRIBUTES',
    section: SECTION_SETTINGS,
    icon: ICON_CODE,
    routeName: 'attributes_list',
  },
  {
    id: 'open_automation_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_AUTOMATION',
    section: SECTION_SETTINGS,
    icon: ICON_REPEAT,
    routeName: 'automation_list',
  },
  {
    id: 'open_macro_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_MACROS',
    section: SECTION_SETTINGS,
    icon: ICON_TOY_BRICK,
    routeName: 'macros_wrapper',
  },
  {
    id: 'open_canned_response_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_CANNED_RESPONSES',
    section: SECTION_SETTINGS,
    icon: ICON_MESSAGE_QUOTE,
    routeName: 'canned_list',
  },
  {
    id: 'open_sla_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_SLA',
    section: SECTION_SETTINGS,
    icon: ICON_CLOCK_ALERT,
    routeName: 'sla_list',
  },
  {
    id: 'open_applications_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_APPLICATIONS',
    section: SECTION_SETTINGS,
    icon: ICON_BLOCKS,
    routeName: 'settings_applications',
  },
  {
    id: 'open_data_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_DATA',
    section: SECTION_SETTINGS,
    icon: ICON_DATABASE,
    routeName: 'settings_data_imports',
  },
  {
    id: 'open_audit_logs_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_AUDIT_LOGS',
    section: SECTION_SETTINGS,
    icon: ICON_BRIEFCASE,
    routeName: 'auditlogs_list',
  },
  {
    id: 'open_billing_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_BILLING',
    section: SECTION_SETTINGS,
    icon: ICON_CREDIT_CARD,
    routeName: 'billing_settings_index',
  },
  {
    id: 'open_account_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_ACCOUNT',
    section: SECTION_SETTINGS,
    icon: ICON_BRIEFCASE,
    routeName: 'general_settings_index',
  },
  {
    id: 'open_profile_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_PROFILE',
    section: SECTION_SETTINGS,
    icon: ICON_USER_PEN,
    routeName: 'profile_settings_index',
  },
];

export function useGoToCommandHotKeys(isPaywalled = ref(false)) {
  const { t } = useI18n();
  const router = useRouter();
  const { checkPermissions, checkInstallationType, isFeatureFlagEnabled } =
    usePolicy();

  const currentAccountId = useMapGetter('getCurrentAccountId');

  // Resolve by name, not path: paths can land on redirect records with no meta,
  // which would leave the command ungated.
  const resolveRoute = command =>
    router.resolve({
      name: command.routeName,
      params: { accountId: currentAccountId.value, ...command.params },
    });

  const isAvailable = route => {
    const { meta } = route;

    if (!isFeatureFlagEnabled(meta?.featureFlag)) return false;
    if (!checkPermissions(meta?.permissions)) return false;
    if (!checkInstallationType(meta?.installationTypes)) return false;

    return !isPaywalled.value || isUpgradePageBypassRoute(route.name);
  };

  const goToCommandHotKeys = computed(() =>
    GO_TO_COMMANDS.flatMap(command => {
      const route = resolveRoute(command);
      if (!isAvailable(route)) return [];

      return {
        id: command.id,
        section: t(command.section),
        title: t(command.title),
        icon: command.icon,
        handler: () => router.push(route),
      };
    })
  );

  return {
    goToCommandHotKeys,
  };
}
