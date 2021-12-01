<template>
  <div class="main-nav secondary-menu">
    <transition-group name="menu-list" tag="ul" class="menu vertical">
      <sidebar-item
        v-if="shouldShowConversationsSideMenu"
        :key="inboxSection.toState"
        :menu-item="inboxSection"
      />
      <sidebar-item
        v-if="shouldShowTeamsSideMenu"
        :key="teamSection.toState"
        :menu-item="teamSection"
      />
      <sidebar-item
        v-if="shouldShowConversationsSideMenu"
        :key="labelSection.toState"
        :menu-item="labelSection"
        @add-label="showAddLabelPopup"
      />
      <sidebar-item
        v-if="shouldShowContactSideMenu"
        :key="contactLabelSection.key"
        :menu-item="contactLabelSection"
        @add-label="showAddLabelPopup"
      />
      <sidebar-item
        v-if="shouldShowCampaignSideMenu"
        :key="campaignSubSection.key"
        :menu-item="campaignSubSection"
      />
      <sidebar-item
        v-if="shouldShowReportsSideMenu"
        :key="reportsSubSection.key"
        :menu-item="reportsSubSection"
      />
      <sidebar-item
        v-if="shouldShowSettingsSideMenu"
        :key="settingsSubMenu.key"
        :menu-item="settingsSubMenu"
      />
      <sidebar-item
        v-if="shouldShowNotificationsSideMenu"
        :key="notificationsSubMenu.key"
        :menu-item="notificationsSubMenu"
      />
    </transition-group>
  </div>
</template>
<script>
import { frontendURL } from '../../../helper/URLHelper';
import SidebarItem from 'dashboard/components/layout/SidebarItem';
import routesMixin from 'dashboard/modules/sidebar/mixins/routes.mixin';

export default {
  components: {
    SidebarItem,
  },
  mixins: [routesMixin],
  props: {
    accountId: {
      type: Number,
      default: 0,
    },
    accountLabels: {
      type: Array,
      default: () => [],
    },
    inboxes: {
      type: Array,
      default: () => [],
    },
    teams: {
      type: Array,
      default: () => [],
    },
    menuItems: {
      type: Array,
      default: () => [],
    },
  },
  computed: {
    inboxSection() {
      return {
        icon: 'folder',
        label: 'INBOXES',
        hasSubMenu: true,
        newLink: true,
        newLinkTag: 'NEW_INBOX',
        key: 'inbox',
        cssClass: 'menu-title align-justify',
        toState: frontendURL(`accounts/${this.accountId}/settings/inboxes/new`),
        toStateName: 'settings_inbox_new',
        newLinkRouteName: 'settings_inbox_new',
        children: this.inboxes.map(inbox => ({
          id: inbox.id,
          label: inbox.name,
          truncateLabel: true,
          toState: frontendURL(`accounts/${this.accountId}/inbox/${inbox.id}`),
          type: inbox.channel_type,
          phoneNumber: inbox.phone_number,
        })),
      };
    },
    labelSection() {
      return {
        icon: 'number-symbol',
        label: 'LABELS',
        hasSubMenu: true,
        newLink: true,
        newLinkTag: 'NEW_LABEL',
        key: 'label',
        cssClass: 'menu-title align-justify',
        toState: frontendURL(`accounts/${this.accountId}/settings/labels`),
        toStateName: 'labels_list',
        showModalForNewItem: true,
        modalName: 'AddLabel',
        children: this.accountLabels.map(label => ({
          id: label.id,
          label: label.title,
          color: label.color,
          truncateLabel: true,
          toState: frontendURL(
            `accounts/${this.accountId}/label/${label.title}`
          ),
        })),
      };
    },
    contactLabelSection() {
      return {
        icon: 'number-symbol',
        label: 'TAGGED_WITH',
        hasSubMenu: true,
        key: 'label',
        newLink: true,
        newLinkTag: 'NEW_LABEL',
        cssClass: 'menu-title align-justify',
        toState: frontendURL(`accounts/${this.accountId}/settings/labels`),
        toStateName: 'labels_list',
        showModalForNewItem: true,
        modalName: 'AddLabel',
        children: this.accountLabels.map(label => ({
          id: label.id,
          label: label.title,
          color: label.color,
          truncateLabel: true,
          toState: frontendURL(
            `accounts/${this.accountId}/labels/${label.title}/contacts`
          ),
        })),
      };
    },
    campaignSubSection() {
      return this.getSubSectionByKey('campaigns');
    },
    teamSection() {
      return {
        icon: 'people-team',
        label: 'TEAMS',
        hasSubMenu: true,
        newLink: true,
        newLinkTag: 'NEW_TEAM',
        key: 'team',
        cssClass: 'menu-title align-justify teams-sidebar-menu',
        toState: frontendURL(`accounts/${this.accountId}/settings/teams/new`),
        toStateName: 'settings_teams_new',
        newLinkRouteName: 'settings_teams_new',
        children: this.teams.map(team => ({
          id: team.id,
          label: team.name,
          truncateLabel: true,
          toState: frontendURL(`accounts/${this.accountId}/team/${team.id}`),
        })),
      };
    },

    notificationsSubMenu() {
      return {
        icon: 'alert',
        label: 'NOTIFICATIONS',
        hasSubMenu: false,
        cssClass: 'menu-title align-justify',
        key: 'notifications',
        children: [],
      };
    },
    settingsSubMenu() {
      return this.getSubSectionByKey('settings');
    },
    reportsSubSection() {
      return this.getSubSectionByKey('reports');
    },
  },
  methods: {
    getSubSectionByKey(subSectionKey) {
      const menuItems = Object.values(
        this.sideMenuItems[subSectionKey].menuItems
      );
      const campaignItem = this.menuItems.find(
        ({ key }) => key === subSectionKey
      );

      return {
        ...campaignItem,
        children: menuItems.map(item => ({
          ...item,
          label: this.$t(`SIDEBAR.${item.label}`),
        })),
      };
    },
    showAddLabelPopup() {
      this.$emit('add-label');
    },
  },
};
</script>
