import {
  ICON_AGENT_REPORTS,
  ICON_CONTACT_DASHBOARD,
  ICON_CONVERSATION_DASHBOARD,
  ICON_INBOX_REPORTS,
  ICON_LABEL_REPORTS,
  ICON_REPORTS_OVERVIEW,
  ICON_TEAM_REPORTS,
} from './CommandBarIcons';
import { frontendURL } from '../../../helper/URLHelper';

export default {
  computed: {
    goToCommandHotKeys() {
      return [
        {
          id: 'goto_conversation_dashboard',
          title: this.$t('COMMAND_BAR.COMMANDS.GO_TO_CONVERSATION_DASHBOARD'),
          section: this.$t('COMMAND_BAR.SECTIONS.GENERAL'),
          icon: ICON_CONVERSATION_DASHBOARD,
          handler: () => this.openRoute(`accounts/${this.accountId}/dashboard`),
        },
        {
          id: 'goto_contacts_dashboard',
          title: this.$t('COMMAND_BAR.COMMANDS.GO_TO_CONTACTS_DASHBOARD'),
          section: this.$t('COMMAND_BAR.SECTIONS.GENERAL'),
          icon: ICON_CONTACT_DASHBOARD,
          handler: () => this.openRoute(`accounts/${this.accountId}/contacts`),
        },
        {
          id: 'open_reports_overview',
          section: this.$t('COMMAND_BAR.SECTIONS.REPORTS'),
          title: this.$t('COMMAND_BAR.COMMANDS.GO_TO_REPORTS_OVERVIEW'),
          icon: ICON_REPORTS_OVERVIEW,
          handler: () =>
            this.openRoute(`accounts/${this.accountId}/reports/overview`),
        },
        {
          id: 'open_agent_reports',
          section: this.$t('COMMAND_BAR.SECTIONS.REPORTS'),
          title: this.$t('COMMAND_BAR.COMMANDS.GO_TO_AGENT_REPORTS'),
          icon: ICON_AGENT_REPORTS,
          handler: () =>
            this.openRoute(`accounts/${this.accountId}/reports/agent`),
        },
        {
          id: 'open_label_reports',
          section: this.$t('COMMAND_BAR.SECTIONS.REPORTS'),
          title: this.$t('COMMAND_BAR.COMMANDS.GO_TO_LABEL_REPORTS'),
          icon: ICON_LABEL_REPORTS,
          handler: () =>
            this.openRoute(`accounts/${this.accountId}/reports/label`),
        },
        {
          id: 'open_inbox_reports',
          section: this.$t('COMMAND_BAR.SECTIONS.REPORTS'),
          title: this.$t('COMMAND_BAR.COMMANDS.GO_TO_INBOX_REPORTS'),
          icon: ICON_INBOX_REPORTS,
          handler: () =>
            this.openRoute(`accounts/${this.accountId}/reports/inboxes`),
        },
        {
          id: 'open_team_reports',
          section: this.$t('COMMAND_BAR.SECTIONS.REPORTS'),
          title: this.$t('COMMAND_BAR.COMMANDS.GO_TO_TEAM_REPORTS'),
          icon: ICON_TEAM_REPORTS,
          handler: () =>
            this.openRoute(`accounts/${this.accountId}/reports/teams`),
        },
      ];
    },
  },
  methods: {
    openRoute(url) {
      this.$router.push(frontendURL(url));
    },
  },
};
