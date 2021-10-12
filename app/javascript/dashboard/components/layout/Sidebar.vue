<template>
  <aside class="woot-sidebar" :class="{ 'only-primary': !showSecondaryMenu }">
    <primary-sidebar
      :logo-source="globalConfig.logo"
      :installation-name="globalConfig.installationName"
      :account-id="accountId"
      :menu-items="primaryMenuItems"
      @toggle-accounts="toggleAccountModal"
    />

    <secondary-sidebar
      v-if="showSecondaryMenu"
      :account-id="accountId"
      :inboxes="inboxes"
      :account-labels="accountLabels"
      :teams="teams"
      :menu-items="primaryMenuItems"
      @add-label="showAddLabelPopup"
    />

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
import { getSidebarItems } from '../../i18n/default-sidebar';
import alertMixin from 'shared/mixins/alertMixin';

import AccountSelector from './sidebarComponents/AccountSelector.vue';
import AddAccountModal from './sidebarComponents/AddAccountModal.vue';
import AddLabelModal from '../../routes/dashboard/settings/labels/AddLabel';
import PrimarySidebar from 'dashboard/modules/sidebar/components/Primary';
import SecondarySidebar from 'dashboard/modules/sidebar/components/Secondary';
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
    AccountSelector,
    AddAccountModal,
    AddLabelModal,
    PrimarySidebar,
    SecondarySidebar,
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
    currentRoute() {
      return this.$store.state.route.name;
    },
    shouldShowNotificationsSideMenu() {
      return this.sidemenuItems.notifications.routes.includes(
        this.currentRoute
      );
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
