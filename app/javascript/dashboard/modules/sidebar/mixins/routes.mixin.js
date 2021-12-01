import { getSidebarItems } from 'dashboard/i18n/default-sidebar';

export default {
  computed: {
    currentRoute() {
      return this.$store.state.route.name;
    },
    sideMenuItems() {
      return getSidebarItems(this.accountId);
    },
    shouldShowConversationsSideMenu() {
      return this.sideMenuItems.common.routes.includes(this.currentRoute);
    },
    shouldShowContactSideMenu() {
      return this.sideMenuItems.contacts.routes.includes(this.currentRoute);
    },
    shouldShowCampaignSideMenu() {
      return this.sideMenuItems.campaigns.routes.includes(this.currentRoute);
    },
    shouldShowSettingsSideMenu() {
      return this.sideMenuItems.settings.routes.includes(this.currentRoute);
    },
    shouldShowReportsSideMenu() {
      return this.sideMenuItems.reports.routes.includes(this.currentRoute);
    },
    shouldShowNotificationsSideMenu() {
      return this.sideMenuItems.notifications.routes.includes(
        this.currentRoute
      );
    },
    shouldShowTeamsSideMenu() {
      return this.shouldShowConversationsSideMenu && this.teams.length;
    },
  },
};
