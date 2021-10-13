import { getSidebarItems } from 'dashboard/i18n/default-sidebar';

export default {
  computed: {
    currentRoute() {
      return this.$store.state.route.name;
    },
    sidemenuItems() {
      return getSidebarItems(this.accountId);
    },
    shouldShowConversationsSideMenu() {
      return this.sidemenuItems.common.routes.includes(this.currentRoute);
    },
    shouldShowContactSideMenu() {
      return this.sidemenuItems.contacts.routes.includes(this.currentRoute);
    },
    shouldShowCampaignSideMenu() {
      return this.sidemenuItems.campaigns.routes.includes(this.currentRoute);
    },
    shouldShowSettingsSideMenu() {
      return this.sidemenuItems.settings.routes.includes(this.currentRoute);
    },
    shouldShowReportsSideMenu() {
      return this.sidemenuItems.reports.routes.includes(this.currentRoute);
    },
    shouldShowNotificationsSideMenu() {
      return this.sidemenuItems.notifications.routes.includes(
        this.currentRoute
      );
    },
    shouldShowTeamsSideMenu() {
      return this.shouldShowSidebarItem && this.teams.length;
    },
  },
};
