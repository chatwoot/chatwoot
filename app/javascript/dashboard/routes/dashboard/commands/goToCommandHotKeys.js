import {
  ICON_ACCOUNT_SETTINGS,
  ICON_AGENT_REPORTS,
  ICON_APPS,
  ICON_CANNED_RESPONSE,
  ICON_CONTACT_DASHBOARD,
  ICON_CONVERSATION_DASHBOARD,
  ICON_INBOXES,
  ICON_INBOX_REPORTS,
  ICON_LABELS,
  ICON_LABEL_REPORTS,
  ICON_NOTIFICATION,
  ICON_REPORTS_OVERVIEW,
  ICON_TEAM_REPORTS,
  ICON_USER_PROFILE,
  ICON_CONVERSATION_REPORTS,
} from './CommandBarIcons';
import { frontendURL } from '../../../helper/URLHelper';
import { mapGetters } from 'vuex';
import { FEATURE_FLAGS } from '../../../featureFlags';

const GO_TO_COMMANDS = [
  {
    id: 'goto_conversation_dashboard',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONVERSATION_DASHBOARD',
    section: 'COMMAND_BAR.SECTIONS.GENERAL',
    icon: ICON_CONVERSATION_DASHBOARD,
    path: accountId => `accounts/${accountId}/dashboard`,
    role: ['administrator', 'agent'],
  },
  {
    id: 'goto_contacts_dashboard',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONTACTS_DASHBOARD',
    section: 'COMMAND_BAR.SECTIONS.GENERAL',
    featureFlag: FEATURE_FLAGS.CRM,
    icon: ICON_CONTACT_DASHBOARD,
    path: accountId => `accounts/${accountId}/contacts`,
    role: ['administrator', 'agent'],
  },
  {
    id: 'open_reports_overview',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_REPORTS_OVERVIEW',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_REPORTS_OVERVIEW,
    path: accountId => `accounts/${accountId}/reports/overview`,
    role: ['administrator'],
  },
  {
    id: 'open_conversation_reports',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_CONVERSATION_REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_CONVERSATION_REPORTS,
    path: accountId => `accounts/${accountId}/reports/conversation`,
    role: ['administrator'],
  },
  {
    id: 'open_agent_reports',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_AGENT_REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_AGENT_REPORTS,
    path: accountId => `accounts/${accountId}/reports/agent`,
    role: ['administrator'],
  },
  {
    id: 'open_label_reports',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_LABEL_REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_LABEL_REPORTS,
    path: accountId => `accounts/${accountId}/reports/label`,
    role: ['administrator'],
  },
  {
    id: 'open_inbox_reports',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_INBOX_REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_INBOX_REPORTS,
    path: accountId => `accounts/${accountId}/reports/inboxes`,
    role: ['administrator'],
  },
  {
    id: 'open_team_reports',
    section: 'COMMAND_BAR.SECTIONS.REPORTS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_TEAM_REPORTS',
    featureFlag: FEATURE_FLAGS.REPORTS,
    icon: ICON_TEAM_REPORTS,
    path: accountId => `accounts/${accountId}/reports/teams`,
    role: ['administrator'],
  },
  {
    id: 'open_agent_settings',
    section: 'COMMAND_BAR.SECTIONS.SETTINGS',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_AGENTS',
    featureFlag: FEATURE_FLAGS.AGENT_MANAGEMENT,
    icon: ICON_AGENT_REPORTS,
    path: accountId => `accounts/${accountId}/settings/agents/list`,
    role: ['administrator'],
  },
  {
    id: 'open_team_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_TEAMS',
    featureFlag: FEATURE_FLAGS.TEAM_MANAGEMENT,
    section: 'COMMAND_BAR.SECTIONS.SETTINGS',
    icon: ICON_TEAM_REPORTS,
    path: accountId => `accounts/${accountId}/settings/teams/list`,
    role: ['administrator'],
  },
  {
    id: 'open_inbox_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_INBOXES',
    featureFlag: FEATURE_FLAGS.INBOX_MANAGEMENT,
    section: 'COMMAND_BAR.SECTIONS.SETTINGS',
    icon: ICON_INBOXES,
    path: accountId => `accounts/${accountId}/settings/inboxes/list`,
    role: ['administrator'],
  },
  {
    id: 'open_label_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_LABELS',
    featureFlag: FEATURE_FLAGS.LABELS,
    section: 'COMMAND_BAR.SECTIONS.SETTINGS',
    icon: ICON_LABELS,
    path: accountId => `accounts/${accountId}/settings/labels/list`,
    role: ['administrator'],
  },
  {
    id: 'open_canned_response_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_CANNED_RESPONSES',
    featureFlag: FEATURE_FLAGS.CANNED_RESPONSES,
    section: 'COMMAND_BAR.SECTIONS.SETTINGS',
    icon: ICON_CANNED_RESPONSE,
    path: accountId => `accounts/${accountId}/settings/canned-response/list`,
    role: ['administrator', 'agent'],
  },
  {
    id: 'open_applications_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_APPLICATIONS',
    featureFlag: FEATURE_FLAGS.INTEGRATIONS,
    section: 'COMMAND_BAR.SECTIONS.SETTINGS',
    icon: ICON_APPS,
    path: accountId => `accounts/${accountId}/settings/applications`,
    role: ['administrator'],
  },
  {
    id: 'open_account_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_ACCOUNT',
    section: 'COMMAND_BAR.SECTIONS.SETTINGS',
    icon: ICON_ACCOUNT_SETTINGS,
    path: accountId => `accounts/${accountId}/settings/general`,
    role: ['administrator'],
  },
  {
    id: 'open_profile_settings',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_SETTINGS_PROFILE',
    section: 'COMMAND_BAR.SECTIONS.SETTINGS',
    icon: ICON_USER_PROFILE,
    path: accountId => `accounts/${accountId}/profile/settings`,
    role: ['administrator', 'agent'],
  },
  {
    id: 'open_notifications',
    title: 'COMMAND_BAR.COMMANDS.GO_TO_NOTIFICATIONS',
    section: 'COMMAND_BAR.SECTIONS.SETTINGS',
    icon: ICON_NOTIFICATION,
    path: accountId => `accounts/${accountId}/notifications`,
    role: ['administrator', 'agent'],
  },
];

export default {
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
    }),
    goToCommandHotKeys() {
      let commands = GO_TO_COMMANDS.filter(cmd => {
        if (cmd.featureFlag) {
          return this.isFeatureEnabledonAccount(
            this.accountId,
            cmd.featureFlag
          );
        }
        return true;
      });

      if (!this.isAdmin) {
        commands = commands.filter(command => command.role.includes('agent'));
      }

      return commands.map(command => ({
        id: command.id,
        section: this.$t(command.section),
        title: this.$t(command.title),
        icon: command.icon,
        handler: () => this.openRoute(command.path(this.accountId)),
      }));
    },
  },
  methods: {
    openRoute(url) {
      this.$router.push(frontendURL(url));
    },
  },
};
