<template>
  <aside class="woot-sidebar" :class="{ 'only-primary': !showSecondaryMenu }">
    <primary-sidebar
      :logo-source="globalConfig.logo"
      :installation-name="globalConfig.installationName"
      :account-id="accountId"
      :menu-items="primaryMenuItems"
      @toggle-accounts="toggleAccountModal"
    />

    <div v-if="showSecondaryMenu" class="main-nav secondary-menu">
      <transition-group name="menu-list" tag="ul" class="menu vertical">
        <sidebar-item
          v-if="shouldShowSidebarItem"
          :key="inboxSection.toState"
          :menu-item="inboxSection"
        />
        <sidebar-item
          v-if="shouldShowTeams"
          :key="teamSection.toState"
          :menu-item="teamSection"
        />
        <sidebar-item
          v-if="shouldShowSidebarItem"
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

    <woot-key-shortcut-modal
      v-if="showShortcutModal"
      @close="closeKeyShortcutModal"
      @clickaway="closeKeyShortcutModal"
    />

    <account-selector
      :show-account-modal="showAccountModal"
      @close-account-modal="toggleAccountModal"
      @show-create-account-modal="openCreateAccountModal"
    />

    <add-account-modal
      :show="showCreateAccountModal"
      @close-account-create-modal="closeCreateAccountModal"
    />

    <woot-modal :show.sync="showAddLabelModal" :on-close="hideAddLabelPopup">
      <add-label-modal @close="hideAddLabelPopup" />
    </woot-modal>
  </aside>
</template>

<script>
import { mapGetters } from 'vuex';

import adminMixin from '../../mixins/isAdmin';
import SidebarItem from './SidebarItem';
import { frontendURL } from '../../helper/URLHelper';
import { getSidebarItems } from '../../i18n/default-sidebar';
import alertMixin from 'shared/mixins/alertMixin';

import AccountSelector from './sidebarComponents/AccountSelector.vue';
import AddAccountModal from './sidebarComponents/AddAccountModal.vue';
import AddLabelModal from '../../routes/dashboard/settings/labels/AddLabel';
import PrimarySidebar from 'dashboard/modules/sidebar/components/Primary';
import WootKeyShortcutModal from 'components/widgets/modal/WootKeyShortcutModal';
import {
  hasPressedAltAndCKey,
  hasPressedAltAndRKey,
  hasPressedAltAndSKey,
  hasPressedAltAndVKey,
  hasPressedCommandAndForwardSlash,
  isEscape,
} from 'shared/helpers/KeyboardHelpers';
import eventListenerMixins from 'shared/mixins/eventListenerMixins';
import router from '../../routes';

export default {
  components: {
    SidebarItem,
    AccountSelector,
    AddAccountModal,
    AddLabelModal,
    PrimarySidebar,
    WootKeyShortcutModal,
  },
  mixins: [adminMixin, alertMixin, eventListenerMixins],
  data() {
    return {
      showOptionsMenu: false,
      showAccountModal: false,
      showCreateAccountModal: false,
      showAddLabelModal: false,
      showShortcutModal: false,
    };
  },

  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      inboxes: 'inboxes/getInboxes',
      accountId: 'getCurrentAccountId',
      currentRole: 'getCurrentRole',
      accountLabels: 'labels/getLabelsOnSidebar',
      teams: 'teams/getMyTeams',
    }),

    sidemenuItems() {
      return getSidebarItems(this.accountId);
    },
    primaryMenuItems() {
      const menuItems = Object.values(
        getSidebarItems(this.accountId).common.menuItems
      );

      return menuItems;
    },
    accessibleMenuItems() {
      // get all keys in menuGroup
      const groupKey = Object.keys(this.sidemenuItems);

      let menuItems = [];
      // Iterate over menuGroup to find the correct group
      for (let i = 0; i < groupKey.length; i += 1) {
        const groupItem = this.sidemenuItems[groupKey[i]];
        // Check if current route is included
        const isRouteIncluded = groupItem.routes.includes(this.currentRoute);
        if (isRouteIncluded) {
          menuItems = Object.values(groupItem.menuItems);
        }
      }

      return this.filterMenuItemsByRole(menuItems);
    },
    currentRoute() {
      return this.$store.state.route.name;
    },
    shouldShowSidebarItem() {
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
    shouldShowTeams() {
      return this.shouldShowSidebarItem && this.teams.length;
    },
    inboxSection() {
      return {
        icon: 'ion-folder',
        label: 'INBOXES',
        hasSubMenu: true,
        newLink: true,
        newLinkTag: 'NEW_INBOX',
        key: 'inbox',
        cssClass: 'menu-title align-justify',
        toState: frontendURL(`accounts/${this.accountId}/settings/inboxes`),
        toStateName: 'settings_inbox_list',
        newLinkRouteName: 'settings_inbox_new',
        children: this.inboxes.map(inbox => ({
          id: inbox.id,
          label: inbox.name,
          toState: frontendURL(`accounts/${this.accountId}/inbox/${inbox.id}`),
          type: inbox.channel_type,
          phoneNumber: inbox.phone_number,
        })),
      };
    },
    labelSection() {
      return {
        icon: 'ion-pound',
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
        icon: 'ion-pound',
        label: 'TAGGED_WITH',
        hasSubMenu: true,
        key: 'label',
        newLink: false,
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
        icon: 'ion-ios-people',
        label: 'TEAMS',
        hasSubMenu: true,
        newLink: true,
        newLinkTag: 'NEW_TEAM',
        key: 'team',
        cssClass: 'menu-title align-justify teams-sidebar-menu',
        toState: frontendURL(`accounts/${this.accountId}/settings/teams`),
        toStateName: 'teams_list',
        newLinkRouteName: 'settings_teams_new',
        children: this.teams.map(team => ({
          id: team.id,
          label: team.name,
          truncateLabel: true,
          toState: frontendURL(`accounts/${this.accountId}/team/${team.id}`),
        })),
      };
    },
    settingsSubMenu() {
      return this.getSubSectionByKey('settings');
    },
    reportsSubSection() {
      return this.getSubSectionByKey('reports');
    },
    notificationsSubMenu() {
      return {
        icon: 'ion-ios-bell',
        label: 'NOTIFICATIONS',
        hasSubMenu: false,
        cssClass: 'menu-title align-justify',
        key: 'notifications',
        children: [],
      };
    },
    dashboardPath() {
      return frontendURL(`accounts/${this.accountId}/dashboard`);
    },
    showSecondaryMenu() {
      if (this.shouldShowNotificationsSideMenu) return false;
      return true;
    },
  },
  mounted() {
    this.$store.dispatch('labels/get');
    this.$store.dispatch('inboxes/get');
    this.$store.dispatch('notifications/unReadCount');
    this.$store.dispatch('teams/get');
  },

  methods: {
    getSubSectionByKey(subSectionKey) {
      const menuItems = Object.values(
        this.sidemenuItems[subSectionKey].menuItems
      );
      const campaignItem = this.primaryMenuItems.find(
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
    toggleKeyShortcutModal() {
      this.showShortcutModal = true;
    },
    closeKeyShortcutModal() {
      this.showShortcutModal = false;
    },
    handleKeyEvents(e) {
      if (hasPressedCommandAndForwardSlash(e)) {
        this.toggleKeyShortcutModal();
      }
      if (isEscape(e)) {
        this.closeKeyShortcutModal();
      }

      if (hasPressedAltAndCKey(e)) {
        if (!this.isCurrentRouteSameAsNavigation('home')) {
          router.push({ name: 'home' });
        }
      } else if (hasPressedAltAndVKey(e)) {
        if (!this.isCurrentRouteSameAsNavigation('contacts_dashboard')) {
          router.push({ name: 'contacts_dashboard' });
        }
      } else if (hasPressedAltAndRKey(e)) {
        if (!this.isCurrentRouteSameAsNavigation('settings_account_reports')) {
          router.push({ name: 'settings_account_reports' });
        }
      } else if (hasPressedAltAndSKey(e)) {
        if (!this.isCurrentRouteSameAsNavigation('agent_list')) {
          router.push({ name: 'agent_list' });
        }
      }
    },
    isCurrentRouteSameAsNavigation(routeName) {
      return router.currentRoute && router.currentRoute.name === routeName;
    },
    toggleSupportChatWindow() {
      window.$chatwoot.toggle();
    },
    filterMenuItemsByRole(menuItems) {
      if (!this.currentRole) {
        return [];
      }
      return menuItems.filter(
        menuItem =>
          window.roleWiseRoutes[this.currentRole].indexOf(
            menuItem.toStateName
          ) > -1
      );
    },

    toggleAccountModal() {
      this.showAccountModal = !this.showAccountModal;
    },
    openCreateAccountModal() {
      this.showAccountModal = false;
      this.showCreateAccountModal = true;
    },
    closeCreateAccountModal() {
      this.showCreateAccountModal = false;
    },
    showAddLabelPopup() {
      this.showAddLabelModal = true;
    },
    hideAddLabelPopup() {
      this.showAddLabelModal = false;
    },
  },
};
</script>

<style lang="scss" scoped>
.woot-sidebar {
  display: flex;

  &.only-primary {
    width: auto;
  }
}

.secondary-menu {
  background: var(--white);
  border-right: 1px solid var(--s-50);
  height: 100vh;
  width: 20rem;
  flex-shrink: 0;
  overflow: auto;
  padding: var(--space-small);
}
</style>

<style lang="scss">
@import '~dashboard/assets/scss/variables';

.account-selector--modal {
  .modal-container {
    width: 40rem;
  }
}

.account-selector {
  cursor: pointer;
  padding: $space-small $space-large;

  .ion-ios-checkmark {
    font-size: $font-size-big;

    & + .account--details {
      padding-left: $space-normal;
    }
  }

  .account--details {
    padding-left: $space-large + $space-smaller;
  }

  &:last-child {
    margin-bottom: $space-large;
  }

  a {
    align-items: center;
    cursor: pointer;
    display: flex;

    .account--name {
      cursor: pointer;
      font-size: $font-size-medium;
      font-weight: $font-weight-medium;
      line-height: 1;
    }

    .account--role {
      cursor: pointer;
      font-size: $font-size-mini;
      text-transform: capitalize;
    }
  }
}

.app-context-menu {
  align-items: center;
  cursor: pointer;
  display: flex;
  flex-direction: row;
  height: 6rem;
}

.current-user--options {
  font-size: $font-size-big;
  margin-bottom: auto;
  margin-left: auto;
  margin-top: auto;
}

.secondary-menu .nested.vertical.menu {
  margin-left: var(--space-small);
}
</style>
